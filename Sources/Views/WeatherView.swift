import SwiftUI

struct WeatherPage: View {
    @ObservedObject var weatherStore: WeatherStore
    @AppStorage(SettingsKey.weatherEnabled) private var weatherEnabled = false

    var body: some View {
        switch weatherStore.state {
        case .off:
            message(
                "Weather is off",
                detail: "Turn on weather to see local conditions from Apple Weather. Core-Monitor asks for your location only after you turn it on."
            ) {
                Button("Turn On Weather") { weatherEnabled = true }
                    .buttonStyle(.borderedProminent)
            }
        case .needsPermission:
            message("Waiting for location access", detail: "Allow location access in the macOS prompt to see local weather.") {
                EmptyView()
            }
        case .denied:
            message("Location access is off", detail: "Core-Monitor needs your location to request local weather. You can allow it in System Settings.") {
                Button("Open Location Settings") { weatherStore.openLocationSettings() }
            }
        case .loading:
            ProgressView("Loading weather…")
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let reason):
            message("Weather unavailable", detail: reason) {
                Button("Try Again") { weatherStore.refresh() }
            }
        case .loaded(let weather):
            LoadedWeather(weather: weather, attribution: weatherStore.attribution)
        }
    }

    private func message<Actions: View>(_ title: String, detail: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            actions()
        }
        .frame(maxWidth: 480, alignment: .leading)
    }
}

private struct LoadedWeather: View {
    let weather: WeatherSnapshot
    let attribution: WeatherAttributionLinks?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: weather.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 44))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Format.temperature(weather.temperature))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text([weather.condition, weather.locationName].compactMap { $0 }.joined(separator: " · "))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            if weather.hourly.isEmpty == false {
                Panel {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Next hours")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 22) {
                                ForEach(weather.hourly) { hour in
                                    VStack(spacing: 6) {
                                        Text(hour.date, format: .dateTime.hour())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: hour.symbolName)
                                            .symbolRenderingMode(.multicolor)
                                            .frame(height: 20)
                                        Text(Format.temperature(hour.temperature))
                                            .font(.callout.weight(.medium))
                                            .monospacedDigit()
                                        Text(hour.precipitationChance >= 0.1 ? Format.percent(hour.precipitationChance * 100) : " ")
                                            .font(.caption2)
                                            .foregroundStyle(.teal)
                                            .monospacedDigit()
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(title: "High / low", value: "\(Format.temperature(weather.high)) / \(Format.temperature(weather.low))")
                    DetailRow(title: "Feels like", value: Format.temperature(weather.feelsLike))
                    DetailRow(title: "Humidity", value: Format.percent(weather.humidity * 100))
                    DetailRow(title: "Wind", value: weather.wind.formatted(.measurement(width: .abbreviated, usage: .wind, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    DetailRow(title: "Updated", value: weather.updatedAt.formatted(date: .omitted, time: .shortened))
                }
            }

            WeatherAttributionView(attribution: attribution)
        }
    }
}

/// WeatherKit requires the Apple Weather mark and a link to its legal attribution page
/// wherever Apple weather data appears.
struct WeatherAttributionView: View {
    let attribution: WeatherAttributionLinks?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            if let attribution {
                AsyncImage(url: colorScheme == .dark ? attribution.darkMarkURL : attribution.lightMarkURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Text(" Weather").font(.footnote.weight(.semibold))
                }
                .frame(height: 14)
                .accessibilityLabel("Apple Weather")

                Link("Legal Attribution", destination: attribution.legalPageURL)
                    .font(.footnote)
            } else {
                Text(" Weather")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
