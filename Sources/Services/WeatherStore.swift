import Combine
import CoreLocation
import Foundation
import OSLog
import WeatherKit

struct WeatherSnapshot: Sendable {
    let locationName: String
    let sourceName: String
    let symbolName: String
    let condition: String
    let temperatureCelsius: Double
    let highCelsius: Double
    let lowCelsius: Double
    let feelsLikeCelsius: Double
    let humidityPercent: Int
    let windKilometersPerHour: Double
    let precipitationChancePercent: Int?
    let nextRainSummary: String
    let updatedAt: Date
}

struct WeatherAttributionSnapshot: Sendable {
    let serviceName: String
    let lightMarkURL: URL
    let darkMarkURL: URL
    let legalPageURL: URL
    let legalAttributionText: String
}

enum WeatherState {
    case idle
    case needsLocation
    case loading
    case loaded(WeatherSnapshot)
    case unavailable(String)
}

@MainActor
final class WeatherStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var state: WeatherState = .idle
    @Published private(set) var attribution: WeatherAttributionSnapshot?

    let refreshInterval: TimeInterval = 900

    private let logger = Logger(subsystem: "CoreMonitorAppStore", category: "Weather")
    private let locationManager = CLLocationManager()
    private let service = WeatherService()
    private var isStarted = false
    private var refreshTask: Task<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var locationTimeoutTask: Task<Void, Never>?

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }

    func start() {
        guard isStarted == false else { return }
        isStarted = true

        Task { @MainActor [weak self] in
            await self?.refreshNow()
        }

        refreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
                await refreshNow()
            }
        }
    }

    func stop() {
        isStarted = false
        refreshTask?.cancel()
        refreshTask = nil
    }

    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    func refresh() {
        Task { @MainActor [weak self] in
            await self?.refreshNow()
        }
    }

    func refreshNow() async {
        authorizationStatus = locationManager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .notDetermined:
            state = .needsLocation
            return
        case .denied, .restricted:
            state = .unavailable(localized("weather.unavailable.locationAccess"))
            return
        @unknown default:
            state = .unavailable(localized("weather.unavailable.generic"))
            return
        }

        guard let location = await currentLocation() else {
            state = .unavailable(localized("weather.unavailable.locationRequired"))
            return
        }

        state = .loading

        do {
            let weather = try await service.weather(for: location)
            attribution = try await loadAttribution()
            let snapshot = await buildSnapshot(from: weather, location: location)
            state = .loaded(snapshot)
        } catch {
            attribution = nil
            logger.error("Weather refresh failed: \(self.describe(error), privacy: .public)")
            state = .unavailable(weatherErrorMessage(for: error))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.authorizationStatus = manager.authorizationStatus
            if self?.isStarted == true {
                await self?.refreshNow()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let location = locations.last ?? manager.location
            self.locationTimeoutTask?.cancel()
            self.locationTimeoutTask = nil
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.locationTimeoutTask?.cancel()
            self.locationTimeoutTask = nil
            self.locationContinuation?.resume(returning: manager.location)
            self.locationContinuation = nil
        }
    }

    private func currentLocation() async -> CLLocation? {
        if let location = locationManager.location, Self.isFresh(location) {
            return location
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()

            locationTimeoutTask?.cancel()
            locationTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard let self, let locationContinuation else { return }
                self.locationContinuation = nil
                locationContinuation.resume(returning: self.locationManager.location)
            }
        }
    }

    private func loadAttribution() async throws -> WeatherAttributionSnapshot {
        if let attribution {
            return attribution
        }

        let weatherAttribution = try await WeatherService.shared.attribution
        let snapshot = WeatherAttributionSnapshot(
            serviceName: weatherAttribution.serviceName,
            lightMarkURL: weatherAttribution.combinedMarkLightURL,
            darkMarkURL: weatherAttribution.combinedMarkDarkURL,
            legalPageURL: weatherAttribution.legalPageURL,
            legalAttributionText: weatherAttribution.legalAttributionText
        )
        attribution = snapshot
        return snapshot
    }

    private func buildSnapshot(from weather: Weather, location: CLLocation) async -> WeatherSnapshot {
        let current = weather.currentWeather
        let hourlyForecast = weather.hourlyForecast.forecast.first { $0.date >= Date() }
        let precipitationChancePercent = hourlyForecast.map { Int(($0.precipitationChance * 100).rounded()) }

        return WeatherSnapshot(
            locationName: await reverseGeocode(location),
            sourceName: localized("weather.source.apple"),
            symbolName: current.symbolName,
            condition: current.condition.description,
            temperatureCelsius: current.temperature.converted(to: .celsius).value,
            highCelsius: weather.dailyForecast.first?.highTemperature.converted(to: .celsius).value
                ?? current.temperature.converted(to: .celsius).value,
            lowCelsius: weather.dailyForecast.first?.lowTemperature.converted(to: .celsius).value
                ?? current.temperature.converted(to: .celsius).value,
            feelsLikeCelsius: current.apparentTemperature.converted(to: .celsius).value,
            humidityPercent: Int((current.humidity * 100).rounded()),
            windKilometersPerHour: current.wind.speed.converted(to: .kilometersPerHour).value,
            precipitationChancePercent: precipitationChancePercent,
            nextRainSummary: nextRainSummary(from: weather),
            updatedAt: Date()
        )
    }

    private func nextRainSummary(from weather: Weather) -> String {
        let now = Date()

        if let currentHour = weather.hourlyForecast.forecast.first(where: { $0.date >= now }),
           Self.isRainCondition(currentHour.condition) {
            return localized("weather.rain.active")
        }

        if let nextRain = weather.hourlyForecast.forecast.first(where: { hour in
            hour.date >= now && Self.isRainCondition(hour.condition)
        }) {
            return localizedFormat("weather.rain.expected", Self.timeFormatter.string(from: nextRain.date))
        }

        if let likelyRain = weather.hourlyForecast.forecast.first(where: { hour in
            hour.date >= now && hour.precipitationChance >= 0.35
        }) {
            let chance = Int((likelyRain.precipitationChance * 100).rounded())
            return localizedFormat("weather.rain.chance", chance, Self.timeFormatter.string(from: likelyRain.date))
        }

        return localized("weather.rain.none")
    }

    private func reverseGeocode(_ location: CLLocation) async -> String {
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.name
                    ?? localized("weather.location.local")
            }
        } catch {
            return localized("weather.location.local")
        }

        return localized("weather.location.local")
    }

    private func weatherErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        let message = nsError.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if isLocationError(nsError) {
            return localized("weather.unavailable.locationAccess")
        }

        if isWeatherKitSetupError(nsError) {
            return localized("weather.unavailable.setupRequired")
        }

        if isNetworkError(nsError) {
            return localized("weather.unavailable.network")
        }

        if message.isEmpty || message == "(null)" {
            return localized("weather.unavailable.generic")
        }

        return message
    }

    private func isLocationError(_ error: NSError) -> Bool {
        if error.domain == kCLErrorDomain {
            return true
        }

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isLocationError(underlyingError)
        }

        return false
    }

    private func isWeatherKitSetupError(_ error: NSError) -> Bool {
        let normalizedDomain = error.domain.lowercased()
        let normalizedMessage = error.localizedDescription.lowercased()

        if normalizedDomain.contains("wdsjwtauthenticatorservice")
            || normalizedDomain.contains("weatherdaemon.wdsjwt") {
            return true
        }

        if normalizedMessage.contains("invalidjwtresponse")
            || normalizedMessage.contains("authenticatorserviceproxy")
            || normalizedMessage.contains("authenticatorservicelistener")
            || normalizedMessage.contains("weatherdaemon")
            || normalizedMessage.contains("wdsjwt") {
            return true
        }

        if error.code == 0 || error.code == 2, normalizedDomain.contains("weatherdaemon") {
            return true
        }

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isWeatherKitSetupError(underlyingError)
        }

        return false
    }

    private func isNetworkError(_ error: NSError) -> Bool {
        if error.domain == NSURLErrorDomain {
            return true
        }

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isNetworkError(underlyingError)
        }

        return false
    }

    private func describe(_ error: Error) -> String {
        let nsError = error as NSError
        var segments = ["\(nsError.domain) code \(nsError.code)"]

        let description = nsError.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if description.isEmpty == false, description != "(null)" {
            segments.append(description)
        }

        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            segments.append("underlying \(underlyingError.domain) code \(underlyingError.code)")
        }

        return segments.joined(separator: " | ")
    }

    private func localized(_ key: String) -> String {
        AppStrings.localized(key)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, arguments: arguments)
    }

    private static func isFresh(_ location: CLLocation) -> Bool {
        abs(location.timestamp.timeIntervalSinceNow) < 900
    }

    private static func isRainCondition(_ condition: WeatherCondition) -> Bool {
        let rawValue = String(describing: condition).lowercased()
        return rawValue.contains("rain") || rawValue.contains("drizzle") || rawValue.contains("thunder")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
