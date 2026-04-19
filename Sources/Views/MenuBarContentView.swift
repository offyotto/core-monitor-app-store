import AppKit
import SwiftUI

struct MenuBarLabelView: View {
    let snapshot: SystemSnapshot

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
            Text(snapshot.menuBarTitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var store: SystemSnapshotStore
    @ObservedObject var weatherStore: WeatherStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(localized("menu.title"))
                    .font(.headline)
                Text(store.snapshot.hardware.marketingName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            InlineMetricRow(title: localized("menu.summary.cpu"), value: percentageText(store.snapshot.cpu.overallPercent))
            InlineMetricRow(title: localized("menu.summary.memory"), value: percentageText(store.snapshot.memory.usagePercent))
            InlineMetricRow(title: localized("metric.network.down"), value: rateText(store.snapshot.network.downloadRateBytesPerSecond))
            InlineMetricRow(title: localized("metric.network.up"), value: rateText(store.snapshot.network.uploadRateBytesPerSecond))
            InlineMetricRow(title: localized("menu.summary.thermal"), value: thermalTitle(for: store.snapshot.thermal.state))
            InlineMetricRow(title: localized("metric.load1.short"), value: loadText(store.snapshot.activity.oneMinuteLoad))
            InlineMetricRow(title: localized("menu.summary.uptime"), value: uptimeText(store.snapshot.activity.systemUptime))
            InlineMetricRow(title: localized("metric.chip"), value: store.snapshot.hardware.chipName)
            InlineMetricRow(title: localized("menu.summary.cores"), value: coreLayoutText(store.snapshot.hardware))
            InlineMetricRow(title: localized("menu.summary.storage"), value: storageSummary(store.snapshot.storage))

            if store.snapshot.battery.isAvailable {
                InlineMetricRow(title: localized("menu.summary.battery"), value: batterySummary(store.snapshot.battery))
            }

            switch weatherStore.state {
            case .loaded(let weather):
                InlineMetricRow(
                    title: localized("card.weather.title"),
                    value: "\(Int(weather.temperatureCelsius.rounded()))°C \(weather.locationName)"
                )
            case .needsLocation:
                InlineMetricRow(title: localized("card.weather.title"), value: localized("weather.status.locationNeeded"))
            case .loading:
                InlineMetricRow(title: localized("card.weather.title"), value: localized("weather.status.updating"))
            case .unavailable(let message):
                InlineMetricRow(title: localized("card.weather.title"), value: weatherSummary(for: message))
            case .idle:
                EmptyView()
            }

            Divider()
            recentTrendsSection

            Divider()

            HStack(spacing: 10) {
                Button(localized("menu.openDashboard")) {
                    openWindow(id: CoreMonitorAppStoreApp.dashboardWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }

                Button(localized("menu.refresh")) {
                    store.refreshNow()
                    weatherStore.refresh()
                }
            }

            Button(localized("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 360)
        .task {
            weatherStore.start()
        }
    }

    private var recentTrendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized("menu.section.trends"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            trendRow(
                title: localized("menu.summary.cpu"),
                current: percentageText(store.snapshot.cpu.overallPercent),
                peak: peakPercentText(store.cpuHistory),
                values: store.cpuHistory,
                tint: .accentColor
            )

            trendRow(
                title: localized("menu.summary.memory"),
                current: percentageText(store.snapshot.memory.usagePercent),
                peak: peakPercentText(store.memoryHistory),
                values: store.memoryHistory,
                tint: .orange
            )

            trendRow(
                title: localized("metric.network.down"),
                current: rateText(store.snapshot.network.downloadRateBytesPerSecond),
                peak: peakRateText(store.downloadHistory),
                values: store.downloadHistory,
                tint: .blue
            )
        }
    }

    private func percentageText(_ value: Double?) -> String {
        guard let value else {
            return localized("value.calibrating")
        }

        return String(format: "%.0f%%", value)
    }

    private func batterySummary(_ battery: BatterySnapshot) -> String {
        guard let chargePercent = battery.chargePercent else {
            return localized("value.unavailable")
        }

        if battery.isCharging {
            return localizedFormat("battery.summary.charging", chargePercent)
        }

        return "\(chargePercent)%"
    }

    private func thermalTitle(for state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return localized("thermal.nominal.title")
        case .fair:
            return localized("thermal.fair.title")
        case .serious:
            return localized("thermal.serious.title")
        case .critical:
            return localized("thermal.critical.title")
        @unknown default:
            return localized("value.unavailable")
        }
    }

    private func rateText(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond > 0 else {
            return "0 KB/s"
        }

        if bytesPerSecond >= 1_073_741_824 {
            return String(format: "%.2f GB/s", bytesPerSecond / 1_073_741_824)
        }

        if bytesPerSecond >= 1_048_576 {
            return String(format: "%.1f MB/s", bytesPerSecond / 1_048_576)
        }

        return String(format: "%.0f KB/s", bytesPerSecond / 1_024)
    }

    private func loadText(_ value: Double?) -> String {
        guard let value else {
            return localized("value.unavailable")
        }

        return String(format: "%.2f", value)
    }

    private func uptimeText(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let days = totalMinutes / 1_440
        let hours = (totalMinutes % 1_440) / 60
        let minutes = totalMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    private func peakPercentText(_ values: [Double]) -> String {
        guard let peak = values.max() else {
            return localized("value.unavailable")
        }

        return String(format: "%.0f%%", peak)
    }

    private func peakRateText(_ values: [Double]) -> String {
        guard let peak = values.max() else {
            return localized("value.unavailable")
        }

        return rateText(peak)
    }

    private func trendRow(
        title: String,
        current: String,
        peak: String,
        values: [Double],
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.callout.weight(.semibold))

                Spacer()

                Text(current)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            TrendSparkline(values: values, tint: tint, height: 22)

            HStack {
                Text(localized("label.recentSamples"))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(localized("label.peak")) \(peak)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.caption2)
        }
    }

    private func storageSummary(_ storage: StorageSnapshot) -> String {
        guard let availableGB = storage.availableGB, let totalGB = storage.totalGB else {
            return localized("value.unavailable")
        }

        return localizedFormat("menu.storage.free", availableGB, totalGB)
    }

    private func weatherSummary(for message: String) -> String {
        let normalized = message.lowercased()

        if normalized.contains("location") {
            return localized("weather.status.locationOff")
        }

        if normalized.contains("signed build") || normalized.contains("weatherkit") {
            return localized("weather.status.needsSignedBuild")
        }

        return localized("value.unavailable")
    }

    private func coreLayoutText(_ hardware: HardwareSummary) -> String {
        switch (hardware.performanceCoreCount, hardware.efficiencyCoreCount) {
        case let (.some(performance), .some(efficiency)):
            return "\(hardware.logicalCoreCount) (\(performance)P/\(efficiency)E)"
        default:
            return "\(hardware.logicalCoreCount)"
        }
    }

    private func localized(_ key: String) -> String {
        AppStrings.localized(key)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, arguments)
    }
}
