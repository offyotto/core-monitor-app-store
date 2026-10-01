import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview, cpu, memory, storage, network, power, thermal, weather

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .cpu: "CPU"
        case .memory: "Memory"
        case .storage: "Storage"
        case .network: "Network"
        case .power: "Power"
        case .thermal: "Thermal"
        case .weather: "Weather"
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .storage: "internaldrive"
        case .network: "network"
        case .power: "bolt"
        case .thermal: "thermometer.medium"
        case .weather: "cloud.sun"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var store: SystemSnapshotStore
    @ObservedObject var weatherStore: WeatherStore
    @SceneStorage("selectedSection") private var selection: DashboardSection = .overview

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(get: { selection }, set: { selection = $0 ?? .overview })) {
                ForEach(DashboardSection.allCases) { section in
                    NavigationLink(value: section) {
                        SidebarRow(section: section, value: sidebarValue(for: section))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            ScrollView {
                page
                    .padding(24)
                    .frame(maxWidth: 920, alignment: .leading)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle(selection.title)
            .navigationSubtitle(store.snapshot.hardware.marketingName)
        }
    }

    @ViewBuilder
    private var page: some View {
        switch selection {
        case .overview: OverviewPage(store: store, weatherStore: weatherStore, selection: $selection)
        case .cpu: CPUPage(store: store)
        case .memory: MemoryPage(store: store)
        case .storage: StoragePage(storage: store.snapshot.storage)
        case .network: NetworkPage(store: store)
        case .power: PowerPage(battery: store.snapshot.battery)
        case .thermal: ThermalPage(thermal: store.snapshot.thermal)
        case .weather: WeatherPage(weatherStore: weatherStore)
        }
    }

    private func sidebarValue(for section: DashboardSection) -> String? {
        let snapshot = store.snapshot
        switch section {
        case .overview: return nil
        case .cpu: return Format.percent(snapshot.cpu.overallPercent)
        case .memory: return Format.percent(snapshot.memory.usagePercent)
        case .storage: return Format.percent(snapshot.storage.usagePercent)
        case .network: return Format.rate(snapshot.network.downloadBytesPerSecond)
        case .power: return snapshot.battery.chargePercent.map { "\($0)%" }
        case .thermal: return snapshot.thermal.state.title
        case .weather:
            if case .loaded(let weather) = weatherStore.state { return Format.temperature(weather.temperature) }
            return nil
        }
    }
}

private struct SidebarRow: View {
    let section: DashboardSection
    let value: String?

    var body: some View {
        HStack {
            Label(section.title, systemImage: section.symbolName)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Overview

private struct OverviewPage: View {
    @ObservedObject var store: SystemSnapshotStore
    @ObservedObject var weatherStore: WeatherStore
    @Binding var selection: DashboardSection

    private let columns = [GridItem(.adaptive(minimum: 250), spacing: 12)]

    var body: some View {
        let snapshot = store.snapshot

        VStack(alignment: .leading, spacing: 16) {
            Text(hardwareLine(snapshot.hardware))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                tile(.cpu, value: Format.percent(snapshot.cpu.overallPercent), detail: coreSplit(snapshot.cpu), tint: .cpuTint) {
                    PercentHistoryChart(samples: store.history, value: \.cpu, tint: .cpuTint, showsAxes: false)
                }

                tile(
                    .memory,
                    value: Format.percent(snapshot.memory.usagePercent),
                    detail: "\(Format.gigabytes(snapshot.memory.usedGB)) of \(Format.gigabytes(snapshot.memory.totalGB)) · Pressure \(snapshot.memory.pressure.title.lowercased())",
                    tint: .memoryTint
                ) {
                    PercentHistoryChart(samples: store.history, value: \.memoryValue, tint: .memoryTint, showsAxes: false)
                }

                tile(.network, value: "↓ \(Format.rate(snapshot.network.downloadBytesPerSecond))", detail: "↑ \(Format.rate(snapshot.network.uploadBytesPerSecond))", tint: .downloadTint) {
                    NetworkHistoryChart(samples: store.history, showsAxes: false)
                }

                tile(.storage, value: "\(Format.bytes(snapshot.storage.availableBytes)) free", detail: "of \(Format.bytes(snapshot.storage.totalBytes)) on \(snapshot.storage.volumeName)", tint: .storageTint) {
                    VStack {
                        Spacer()
                        UsageBar(percent: snapshot.storage.usagePercent, tint: .storageTint, height: 8)
                    }
                }

                tile(.power, value: powerValue(snapshot.battery), detail: powerDetail(snapshot.battery), tint: .powerTint) {
                    VStack {
                        Spacer()
                        if snapshot.battery.isAvailable {
                            UsageBar(percent: snapshot.battery.chargePercent.map(Double.init), tint: .powerTint, height: 8)
                        }
                    }
                }

                tile(.thermal, value: snapshot.thermal.state.title, detail: snapshot.thermal.state.detail, tint: snapshot.thermal.state.color) {
                    Color.clear
                }

                if case .loaded(let weather) = weatherStore.state {
                    tile(.weather, value: Format.temperature(weather.temperature), detail: [weather.condition, weather.locationName].compactMap { $0 }.joined(separator: " · "), tint: .primary) {
                        Color.clear
                    }
                }
            }
        }
    }

    private func tile<Chart: View>(
        _ section: DashboardSection,
        value: String,
        detail: String,
        tint: Color,
        @ViewBuilder chart: () -> Chart
    ) -> some View {
        Button {
            selection = section
        } label: {
            Panel {
                VStack(alignment: .leading, spacing: 6) {
                    Label(section.title, systemImage: section.symbolName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(tint)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText())
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    chart()
                        .frame(height: 40)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows \(section.title) details")
    }

    private func hardwareLine(_ hardware: HardwareSummary) -> String {
        var parts = [hardware.chipName, "\(Format.gigabytes(Double(hardware.physicalMemoryBytes) / 1_073_741_824)) memory"]
        if let performance = hardware.performanceCoreCount, let efficiency = hardware.efficiencyCoreCount {
            parts.append("\(performance) performance and \(efficiency) efficiency cores")
        } else {
            parts.append("\(hardware.logicalCoreCount) cores")
        }
        return parts.joined(separator: " · ")
    }

    private func coreSplit(_ cpu: CPUSnapshot) -> String {
        guard let performance = cpu.performancePercent, let efficiency = cpu.efficiencyPercent else {
            return "All cores"
        }
        return "Performance \(Format.percent(performance)) · Efficiency \(Format.percent(efficiency))"
    }

    private func powerValue(_ battery: BatterySnapshot) -> String {
        guard battery.isAvailable, let charge = battery.chargePercent else { return "AC power" }
        return "\(charge)%"
    }

    private func powerDetail(_ battery: BatterySnapshot) -> String {
        guard battery.isAvailable else { return "No battery in this Mac" }
        guard let minutes = battery.timeRemainingMinutes else { return battery.statusTitle }
        let suffix = battery.isCharging ? "until full" : "remaining"
        return "\(battery.statusTitle) · \(Format.minutes(minutes)) \(suffix)"
    }
}

// MARK: - CPU

private struct CPUPage: View {
    @ObservedObject var store: SystemSnapshotStore

    var body: some View {
        let snapshot = store.snapshot

        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 40) {
                HeadlineValue(value: Format.percent(snapshot.cpu.overallPercent), label: "Total usage", tint: .cpuTint)
                if let performance = snapshot.cpu.performancePercent {
                    HeadlineValue(value: Format.percent(performance), label: "Performance cores")
                }
                if let efficiency = snapshot.cpu.efficiencyPercent {
                    HeadlineValue(value: Format.percent(efficiency), label: "Efficiency cores")
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Last 3 minutes")
                    PercentHistoryChart(samples: store.history, value: \.cpu, tint: .cpuTint)
                        .frame(height: 180)
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Cores", trailing: "\(snapshot.hardware.logicalCoreCount) total")
                    CoreGrid(cores: snapshot.cpu.perCore)
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Load average")
                    DetailRow(title: "1 minute", value: Format.load(snapshot.activity.oneMinuteLoad))
                    DetailRow(title: "5 minutes", value: Format.load(snapshot.activity.fiveMinuteLoad))
                    DetailRow(title: "15 minutes", value: Format.load(snapshot.activity.fifteenMinuteLoad))
                    Divider()
                    DetailRow(title: "Uptime", value: Format.duration(snapshot.activity.systemUptime))
                    Text("A load of 1.0 equals one core's worth of work running or waiting.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CoreGrid: View {
    let cores: [CPUCoreSnapshot]

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(cores) { core in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(core.name)
                            .font(.callout.weight(.medium))
                        Spacer()
                        Text(Format.percent(core.usagePercent))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    UsageBar(percent: core.usagePercent, tint: .cpuTint)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(kindName(core.kind)) core \(core.name)")
                .accessibilityValue(Format.percent(core.usagePercent))
            }
        }
    }

    private func kindName(_ kind: CPUCoreKind) -> String {
        switch kind {
        case .performance: "Performance"
        case .efficiency: "Efficiency"
        case .standard: ""
        }
    }
}

// MARK: - Memory

private struct MemoryPage: View {
    @ObservedObject var store: SystemSnapshotStore

    var body: some View {
        let memory = store.snapshot.memory

        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 40) {
                HeadlineValue(value: Format.percent(memory.usagePercent), label: "In use", tint: .memoryTint)
                HeadlineValue(value: Format.gigabytes(memory.usedGB), label: "of \(Format.gigabytes(memory.totalGB))")
                HeadlineValue(value: memory.pressure.title, label: "Pressure", tint: memory.pressure.color)
            }

            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Last 3 minutes")
                    PercentHistoryChart(samples: store.history, value: \.memoryValue, tint: .memoryTint)
                        .frame(height: 180)
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Breakdown")
                    DetailRow(title: "App memory", value: Format.gigabytes(memory.appGB))
                    DetailRow(title: "Wired memory", value: Format.gigabytes(memory.wiredGB))
                    DetailRow(title: "Compressed", value: Format.gigabytes(memory.compressedGB))
                    Divider()
                    DetailRow(title: "Available", value: Format.gigabytes(memory.availableGB))
                }
            }
        }
    }
}

// MARK: - Storage

private struct StoragePage: View {
    let storage: StorageSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 40) {
                HeadlineValue(value: Format.bytes(storage.availableBytes), label: "Available", tint: .storageTint)
                HeadlineValue(value: Format.percent(storage.usagePercent), label: "Used")
            }

            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: storage.volumeName, trailing: Format.bytes(storage.totalBytes))
                    UsageBar(percent: storage.usagePercent, tint: .storageTint, height: 10)
                    DetailRow(title: "Used", value: Format.bytes(storage.usedBytes))
                    DetailRow(title: "Available", value: Format.bytes(storage.availableBytes))
                }
            }
        }
    }
}

// MARK: - Network

private struct NetworkPage: View {
    @ObservedObject var store: SystemSnapshotStore

    var body: some View {
        let network = store.snapshot.network

        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 40) {
                HeadlineValue(value: Format.rate(network.downloadBytesPerSecond), label: "Download", tint: .downloadTint)
                HeadlineValue(value: Format.rate(network.uploadBytesPerSecond), label: "Upload", tint: .uploadTint)
            }

            Panel {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Last 3 minutes")
                    NetworkHistoryChart(samples: store.history)
                        .frame(height: 180)
                    HStack(spacing: 16) {
                        legend("Download", .downloadTint)
                        legend("Upload", .uploadTint)
                    }
                    .font(.footnote)
                }
            }

            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(title: "Peak download", value: Format.rate(store.history.map(\.download).max() ?? 0))
                    DetailRow(title: "Peak upload", value: Format.rate(store.history.map(\.upload).max() ?? 0))
                }
            }
        }
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Power

private struct PowerPage: View {
    let battery: BatterySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if battery.isAvailable {
                HStack(alignment: .top, spacing: 40) {
                    HeadlineValue(value: battery.chargePercent.map { "\($0)%" } ?? "—", label: "Charge", tint: .powerTint)
                    HeadlineValue(value: battery.statusTitle, label: "Status")
                }

                Panel {
                    VStack(alignment: .leading, spacing: 10) {
                        UsageBar(percent: battery.chargePercent.map(Double.init), tint: .powerTint, height: 10)
                            .padding(.bottom, 4)
                        if let minutes = battery.timeRemainingMinutes {
                            DetailRow(title: battery.isCharging ? "Time until full" : "Time remaining", value: Format.minutes(minutes))
                        }
                        if let health = battery.health {
                            DetailRow(title: "Battery health", value: health)
                        }
                        DetailRow(title: "Low Power Mode", value: battery.lowPowerModeEnabled ? "On" : "Off")
                    }
                }
            } else {
                HeadlineValue(value: "AC power", label: "This Mac has no battery", tint: .powerTint)
                Panel {
                    DetailRow(title: "Low Power Mode", value: battery.lowPowerModeEnabled ? "On" : "Off")
                }
            }
        }
    }
}

// MARK: - Thermal

private struct ThermalPage: View {
    let thermal: ThermalSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeadlineValue(value: thermal.state.title, label: thermal.state.detail, tint: thermal.state.color)

            Panel {
                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(title: "Thermal state", value: thermal.state.title)
                    if thermal.warningLevel != .unavailable {
                        DetailRow(title: "Thermal warning", value: thermal.warningLevel.title)
                    }
                }
            }

            Text("macOS does not give App Store apps access to temperature sensors. This page shows the thermal state that macOS reports, which tells you when the system is slowing down to cool off.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
