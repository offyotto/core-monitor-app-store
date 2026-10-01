import AppKit
import Combine
import CoreLocation
import Foundation
import WeatherKit

struct HourlyWeather: Identifiable {
    let date: Date
    let symbolName: String
    let temperature: Measurement<UnitTemperature>
    let precipitationChance: Double

    var id: Date { date }
}

struct WeatherSnapshot {
    let locationName: String?
    let symbolName: String
    let condition: String
    let temperature: Measurement<UnitTemperature>
    let high: Measurement<UnitTemperature>?
    let low: Measurement<UnitTemperature>?
    let feelsLike: Measurement<UnitTemperature>
    let humidity: Double
    let wind: Measurement<UnitSpeed>
    let hourly: [HourlyWeather]
    let updatedAt: Date
}

struct WeatherAttributionLinks {
    let lightMarkURL: URL
    let darkMarkURL: URL
    let legalPageURL: URL
}

enum WeatherState {
    case off
    case needsPermission
    case denied
    case loading
    case loaded(WeatherSnapshot)
    case failed(String)
}

/// Weather is opt-in. Nothing here touches Location Services until the person
/// turns weather on in Settings, and the only weather source is Apple WeatherKit.
@MainActor
final class WeatherStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var state: WeatherState = .off
    @Published private(set) var attribution: WeatherAttributionLinks?

    private let locationManager = CLLocationManager()
    private let refreshInterval: TimeInterval = 1_800
    private var refreshTask: Task<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var settingsObserver: AnyCancellable?
    private var appliedEnabled: Bool?
    private var isLoading = false

    override init() {
        super.init()
        apply(enabled: isEnabled)
        settingsObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in UserDefaults.standard.bool(forKey: SettingsKey.weatherEnabled) }
            .removeDuplicates()
            .sink { [weak self] enabled in
                Task { @MainActor in self?.apply(enabled: enabled) }
            }
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.weatherEnabled)
    }

    func refresh() {
        guard isEnabled else { return }
        Task { await load() }
    }

    func openLocationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }

    private func apply(enabled: Bool) {
        guard enabled != appliedEnabled else { return }
        appliedEnabled = enabled
        refreshTask?.cancel()
        refreshTask = nil

        guard enabled else {
            locationManager.delegate = nil
            state = .off
            return
        }

        locationManager.delegate = self
        refreshTask = Task { [weak self] in
            while Task.isCancelled == false {
                await self?.load()
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 1_800))
            }
        }
    }

    private func load() async {
        guard isLoading == false else { return }
        isLoading = true
        defer { isLoading = false }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            state = .needsPermission
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            state = .denied
            return
        default:
            break
        }

        if case .loaded = state {} else { state = .loading }

        guard let location = await currentLocation() else {
            state = .failed("Your Mac could not determine its location.")
            return
        }

        do {
            async let weather = WeatherService.shared.weather(for: location)
            async let placeName = Self.placeName(for: location)
            let snapshot = Self.snapshot(from: try await weather, placeName: await placeName)
            state = .loaded(snapshot)
            await loadAttributionIfNeeded()
        } catch {
            state = .failed("Apple Weather is unavailable right now.")
        }
    }

    private func currentLocation() async -> CLLocation? {
        if let location = locationManager.location, abs(location.timestamp.timeIntervalSinceNow) < 900 {
            return location
        }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()

            Task { [weak self] in
                try? await Task.sleep(for: .seconds(15))
                self?.locationContinuation?.resume(returning: nil)
                self?.locationContinuation = nil
            }
        }
    }

    private func loadAttributionIfNeeded() async {
        guard attribution == nil, let value = try? await WeatherService.shared.attribution else { return }
        attribution = WeatherAttributionLinks(
            lightMarkURL: value.combinedMarkLightURL,
            darkMarkURL: value.combinedMarkDarkURL,
            legalPageURL: value.legalPageURL
        )
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard self.isEnabled else { return }
            switch manager.authorizationStatus {
            case .denied, .restricted:
                self.state = .denied
            case .notDetermined:
                break
            default:
                await self.load()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    private static func placeName(for location: CLLocation) async -> String? {
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        return placemark?.locality ?? placemark?.subAdministrativeArea
    }

    private static func snapshot(from weather: Weather, placeName: String?) -> WeatherSnapshot {
        let current = weather.currentWeather
        let today = weather.dailyForecast.first
        let now = Date()
        let hourly = weather.hourlyForecast.forecast
            .filter { $0.date > now.addingTimeInterval(-3_600) }
            .prefix(12)
            .map {
                HourlyWeather(
                    date: $0.date,
                    symbolName: $0.symbolName,
                    temperature: $0.temperature,
                    precipitationChance: $0.precipitationChance
                )
            }

        return WeatherSnapshot(
            locationName: placeName,
            symbolName: current.symbolName,
            condition: current.condition.description,
            temperature: current.temperature,
            high: today?.highTemperature,
            low: today?.lowTemperature,
            feelsLike: current.apparentTemperature,
            humidity: current.humidity,
            wind: current.wind.speed,
            hourly: Array(hourly),
            updatedAt: now
        )
    }
}
