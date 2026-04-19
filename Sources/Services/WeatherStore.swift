import Combine
import CoreLocation
import Foundation
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
    let lightMarkURL: URL
    let darkMarkURL: URL
    let legalPageURL: URL
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
            await self?.loadAttributionIfNeeded()
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
            let snapshot = await buildSnapshot(from: weather, location: location)
            state = .loaded(snapshot)
        } catch let weatherKitError {
            do {
                attribution = nil
                let fallbackSnapshot = try await fallbackSnapshot(for: location)
                state = .loaded(fallbackSnapshot)
            } catch {
                state = .unavailable(weatherErrorMessage(for: weatherKitError))
            }
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

    private func loadAttributionIfNeeded() async {
        guard attribution == nil else { return }

        do {
            let weatherAttribution = try await WeatherService.shared.attribution
            attribution = WeatherAttributionSnapshot(
                lightMarkURL: weatherAttribution.combinedMarkLightURL,
                darkMarkURL: weatherAttribution.combinedMarkDarkURL,
                legalPageURL: weatherAttribution.legalPageURL
            )
        } catch {
            attribution = nil
        }
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

    private func fallbackSnapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        let response = try await fetchOpenMeteoForecast(for: location)
        let locationName = await reverseGeocode(location)
        let presentation = Self.openMeteoPresentation(
            for: response.current.weatherCode,
            isDay: response.current.isDay == 1
        )

        return WeatherSnapshot(
            locationName: locationName,
            sourceName: "Open-Meteo",
            symbolName: presentation.symbolName,
            condition: presentation.condition,
            temperatureCelsius: response.current.temperature,
            highCelsius: response.daily.temperatureMax.first ?? response.current.temperature,
            lowCelsius: response.daily.temperatureMin.first ?? response.current.temperature,
            feelsLikeCelsius: response.current.apparentTemperature,
            humidityPercent: response.current.humidity,
            windKilometersPerHour: response.current.windSpeed,
            precipitationChancePercent: response.daily.precipitationProbabilityMax.first,
            nextRainSummary: nextRainSummary(from: response),
            updatedAt: Date()
        )
    }

    private func fetchOpenMeteoForecast(for location: CLLocation) async throws -> OpenMeteoForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day"
            ),
            URLQueryItem(
                name: "daily",
                value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"
            ),
            URLQueryItem(name: "hourly", value: "precipitation_probability,weather_code"),
            URLQueryItem(name: "forecast_days", value: "2"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
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

    private func nextRainSummary(from forecast: OpenMeteoForecastResponse) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: forecast.utcOffsetSeconds) ?? .current

        let hours = zip(forecast.hourly.time, zip(forecast.hourly.precipitationProbability, forecast.hourly.weatherCode))
        for (timeString, sample) in hours {
            guard let date = formatter.date(from: timeString), date >= Date() else {
                continue
            }

            let precipitationProbability = sample.0
            let weatherCode = sample.1

            if Self.isWetOpenMeteoCode(weatherCode), Calendar.current.isDateInToday(date), abs(date.timeIntervalSinceNow) < 3600 {
                return localized("weather.rain.active")
            }

            if Self.isWetOpenMeteoCode(weatherCode) {
                return localizedFormat("weather.rain.expected", Self.timeFormatter.string(from: date))
            }

            if precipitationProbability >= 35 {
                return localizedFormat("weather.rain.chance", precipitationProbability, Self.timeFormatter.string(from: date))
            }
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
        let message = (error as NSError).localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if message.isEmpty {
            return localized("weather.unavailable.generic")
        }

        let normalized = message.lowercased()
        if normalized.contains("entitlement")
            || normalized.contains("weatherkit")
            || normalized.contains("not authorized")
            || normalized.contains("weatherdaemon")
            || normalized.contains("wdsjwt")
            || normalized.contains("authenticatorserviceproxy") {
            return localized("weather.unavailable.signedBuild")
        }

        return message
    }

    private static func isFresh(_ location: CLLocation) -> Bool {
        abs(location.timestamp.timeIntervalSinceNow) < 900
    }

    private static func isRainCondition(_ condition: WeatherCondition) -> Bool {
        let rawValue = String(describing: condition).lowercased()
        return rawValue.contains("rain") || rawValue.contains("drizzle") || rawValue.contains("thunder")
    }

    private static func isWetOpenMeteoCode(_ code: Int) -> Bool {
        switch code {
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99:
            return true
        default:
            return false
        }
    }

    private static func openMeteoPresentation(for code: Int, isDay: Bool) -> (symbolName: String, condition: String) {
        switch code {
        case 0:
            return (isDay ? "sun.max.fill" : "moon.stars.fill", AppStrings.localized("weather.condition.clear"))
        case 1:
            return (isDay ? "sun.max.fill" : "moon.stars.fill", AppStrings.localized("weather.condition.mainlyClear"))
        case 2:
            return (isDay ? "cloud.sun.fill" : "cloud.moon.fill", AppStrings.localized("weather.condition.partlyCloudy"))
        case 3:
            return ("cloud.fill", AppStrings.localized("weather.condition.overcast"))
        case 45, 48:
            return ("cloud.fog.fill", AppStrings.localized("weather.condition.fog"))
        case 51, 53, 55, 56, 57:
            return ("cloud.drizzle.fill", AppStrings.localized("weather.condition.drizzle"))
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return ("cloud.rain.fill", AppStrings.localized("weather.condition.rain"))
        case 71, 73, 75, 77, 85, 86:
            return ("cloud.snow.fill", AppStrings.localized("weather.condition.snow"))
        case 95, 96, 99:
            return ("cloud.bolt.rain.fill", AppStrings.localized("weather.condition.thunderstorm"))
        default:
            return ("cloud.fill", AppStrings.localized("weather.condition.weather"))
        }
    }

    private func localized(_ key: String) -> String {
        AppStrings.localized(key)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, arguments: arguments)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private struct OpenMeteoForecastResponse: Decodable {
    let utcOffsetSeconds: Int
    let current: Current
    let daily: Daily
    let hourly: Hourly

    enum CodingKeys: String, CodingKey {
        case utcOffsetSeconds = "utc_offset_seconds"
        case current
        case daily
        case hourly
    }

    struct Current: Decodable {
        let temperature: Double
        let humidity: Int
        let apparentTemperature: Double
        let weatherCode: Int
        let windSpeed: Double
        let isDay: Int

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case humidity = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
            case windSpeed = "wind_speed_10m"
            case isDay = "is_day"
        }
    }

    struct Daily: Decodable {
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let precipitationProbabilityMax: [Int]

        enum CodingKeys: String, CodingKey {
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let precipitationProbability: [Int]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case precipitationProbability = "precipitation_probability"
            case weatherCode = "weather_code"
        }
    }
}
