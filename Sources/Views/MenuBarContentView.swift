import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: SystemSnapshotStore
    @ObservedObject var weatherStore: WeatherStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let snapshot = store.snapshot

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.hardware.marketingName)
                    .font(.headline)
                Text(snapshot.hardware.chipName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 10) {
                MeterRow(title: "CPU", symbol: "cpu", value: Format.percent(snapshot.cpu.overallPercent), percent: snapshot.cpu.overallPercent, tint: .cpuTint)
                MeterRow(title: "Memory", symbol: "memorychip", value: Format.percent(snapshot.memory.usagePercent), percent: snapshot.memory.usagePercent, tint: .memoryTint)
                MeterRow(title: "Storage", symbol: "internaldrive", value: "\(Format.bytes(snapshot.storage.availableBytes)) free", percent: snapshot.storage.usagePercent, tint: .storageTint)
                if snapshot.battery.isAvailable {
                    MeterRow(
                        title: "Battery",
                        symbol: snapshot.battery.symbolName,
                        value: snapshot.battery.chargePercent.map { "\($0)%" } ?? "—",
                        percent: snapshot.battery.chargePercent.map(Double.init),
                        tint: .powerTint
                    )
                }
            }

            Divider()

            VStack(spacing: 6) {
                TextRow(title: "Network", symbol: "network", value: "↓ \(Format.rate(snapshot.network.downloadBytesPerSecond))  ↑ \(Format.rate(snapshot.network.uploadBytesPerSecond))")
                TextRow(title: "Thermal", symbol: "thermometer.medium", value: snapshot.thermal.state.title, valueColor: snapshot.thermal.state.color)
                if case .loaded(let weather) = weatherStore.state {
                    TextRow(title: "Weather", symbol: weather.symbolName, value: "\(Format.temperature(weather.temperature)) \(weather.condition)")
                }
            }

            Divider()

            HStack {
                Button("Open Core-Monitor") {
                    openWindow(id: CoreMonitorAppStoreApp.dashboardWindowID)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("o")
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .help("Quit Core-Monitor")
                .keyboardShortcut("q")
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 300)
    }
}

private struct MeterRow: View {
    let title: String
    let symbol: String
    let value: String
    let percent: Double?
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                RowLabel(title: title, symbol: symbol)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
            UsageBar(percent: percent, tint: tint, height: 5)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TextRow: View {
    let title: String
    let symbol: String
    let value: String
    var valueColor: Color = .secondary

    var body: some View {
        HStack {
            RowLabel(title: title, symbol: symbol)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}

struct MenuBarLabelView: View {
    let snapshot: SystemSnapshot
    @AppStorage(SettingsKey.menuBarShowsCPU) private var showsCPU = true
    @AppStorage(SettingsKey.menuBarShowsMemory) private var showsMemory = true
    @AppStorage(SettingsKey.menuBarShowsNetwork) private var showsNetwork = false

    var body: some View {
        let text = segments.joined(separator: "  ")
        if text.isEmpty {
            Image(systemName: snapshot.thermal.isElevated ? "thermometer.high" : "gauge.with.dots.needle.33percent")
        } else {
            Text(snapshot.thermal.isElevated ? "\(text)  HOT" : text)
                .monospacedDigit()
        }
    }

    private var segments: [String] {
        var parts: [String] = []
        if showsCPU { parts.append("CPU \(Format.percent(snapshot.cpu.overallPercent))") }
        if showsMemory { parts.append("MEM \(Format.percent(snapshot.memory.usagePercent))") }
        if showsNetwork { parts.append("↓\(Format.rate(snapshot.network.downloadBytesPerSecond))") }
        return parts
    }
}
