import IOKit.ps
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: SystemSnapshotStore
    @ObservedObject var weatherStore: WeatherStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if proxy.size.width >= 1_040 {
                        wideLayout
                    } else {
                        stackedLayout
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .task {
                weatherStore.start()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localized("dashboard.title"))
                        .font(.largeTitle.weight(.semibold))

                    Text(store.snapshot.hardware.marketingName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(localized("dashboard.lastUpdated"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(store.snapshot.sampledAt, style: .time)
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            Text(localized("dashboard.subtitle"))
                .foregroundStyle(.secondary)

            Text(localized("dashboard.readOnly"))
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

            appSupportLinks

            overviewDetails
        }
    }

    private var appSupportLinks: some View {
        ViewThatFits {
            HStack(spacing: 16) {
                Link(localized("link.privacyPolicy"), destination: AppExternalLinks.privacyPolicy)
                Link(localized("link.support"), destination: AppExternalLinks.support)
            }

            VStack(alignment: .leading, spacing: 8) {
                Link(localized("link.privacyPolicy"), destination: AppExternalLinks.privacyPolicy)
                Link(localized("link.support"), destination: AppExternalLinks.support)
            }
        }
        .font(.callout.weight(.semibold))
    }

    private var overviewDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                localizedFormat(
                    "%@ • %@ • %@",
                    store.snapshot.hardware.modelIdentifier,
                    store.snapshot.hardware.chipName,
                    coreLayoutText(store.snapshot.hardware)
                )
            )

            Text(
                localizedFormat(
                    "%@ unified memory • %@ • Uptime %@",
                    byteCountString(store.snapshot.hardware.physicalMemoryBytes),
                    storageBadgeText(store.snapshot.storage),
                    uptimeText(store.snapshot.activity.systemUptime)
                )
            )
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var wideLayout: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 16) {
                    cpuCard
                    memoryCard
                    networkCard
                    dailyReportCard
                    activityCard
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(spacing: 16) {
                    thermalCard
                    weatherCard
                    powerCard
                    storageCard
                    systemCard
                    calendarCard
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            trendsCard
            perCoreCard
        }
    }

    private var stackedLayout: some View {
        VStack(spacing: 16) {
            cpuCard
            thermalCard
            memoryCard
            weatherCard
            networkCard
            dailyReportCard
            powerCard
            storageCard
            systemCard
            activityCard
            calendarCard
            trendsCard
            perCoreCard
        }
    }

    private var cpuCard: some View {
        DashboardCard(
            title: localized("card.cpu.title"),
            systemImage: "cpu",
            description: localized("card.cpu.description")
        ) {
            gaugeSection(percent: store.snapshot.cpu.overallPercent, tint: .accentColor, detail: nil)

            InlineMetricRow(title: localized("metric.totalCores"), value: "\(store.snapshot.hardware.logicalCoreCount)")

            if let performance = store.snapshot.cpu.performancePercent {
                InlineMetricRow(title: localized("metric.performanceCores"), value: String(format: "%.0f%%", performance))
            }

            if let efficiency = store.snapshot.cpu.efficiencyPercent {
                InlineMetricRow(title: localized("metric.efficiencyCores"), value: String(format: "%.0f%%", efficiency))
            }
        }
    }

    private var thermalCard: some View {
        DashboardCard(
            title: localized("card.thermal.title"),
            systemImage: "thermometer.medium",
            description: localized("card.thermal.description")
        ) {
            Text(thermalTitle(for: store.snapshot.thermal.state))
                .font(.system(size: 32, weight: .semibold, design: .rounded))

            InlineMetricRow(title: localized("metric.thermal.state"), value: thermalTitle(for: store.snapshot.thermal.state))
            InlineMetricRow(title: localized("metric.thermal.warning"), value: thermalWarningTitle(for: store.snapshot.thermal.warningLevel))

            Text(thermalDetail(for: store.snapshot.thermal.state))
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(localized("thermal.publicAPI.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var memoryCard: some View {
        DashboardCard(
            title: localized("card.memory.title"),
            systemImage: "memorychip",
            description: localized("card.memory.description")
        ) {
            gaugeSection(
                percent: store.snapshot.memory.usagePercent,
                tint: memoryTint(for: store.snapshot.memory.pressure),
                detail: localizedFormat("memory.usage.detail", store.snapshot.memory.usedGB, store.snapshot.memory.totalGB)
            )

            InlineMetricRow(title: localized("metric.memory.pressure"), value: memoryPressureTitle(for: store.snapshot.memory.pressure))
            InlineMetricRow(title: localized("metric.memory.app"), value: gigabytesText(store.snapshot.memory.appGB))
            InlineMetricRow(title: localized("metric.memory.wired"), value: gigabytesText(store.snapshot.memory.wiredGB))
            InlineMetricRow(title: localized("metric.memory.compressed"), value: gigabytesText(store.snapshot.memory.compressedGB))
            InlineMetricRow(title: localized("metric.memory.available"), value: gigabytesText(store.snapshot.memory.availableGB))
        }
    }

    private var weatherCard: some View {
        DashboardCard(
            title: localized("card.weather.title"),
            systemImage: "cloud.sun.fill",
            description: localized("card.weather.description")
        ) {
            weatherContent
        }
    }

    @ViewBuilder
    private var weatherContent: some View {
        switch weatherStore.state {
        case .idle, .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text(localized("weather.loading"))
                    .foregroundStyle(.secondary)
            }
        case .needsLocation:
            VStack(alignment: .leading, spacing: 12) {
                Text(localized("weather.enable.title"))
                    .font(.title3.weight(.semibold))

                Text(localized("weather.enable.body"))
                    .foregroundStyle(.secondary)

                Button(localized("weather.enable.button")) {
                    weatherStore.requestLocationAccess()
                }
                .buttonStyle(.borderedProminent)
            }
        case .unavailable(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .foregroundStyle(.secondary)

                Button(localized("weather.retry")) {
                    weatherStore.refresh()
                }
                .buttonStyle(.bordered)
            }
        case .loaded(let snapshot):
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: snapshot.symbolName)
                        .font(.system(size: 28, weight: .medium))
                        .symbolRenderingMode(.multicolor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.locationName)
                            .font(.headline)
                        Text(snapshot.condition)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(String(format: "%.0f°C", snapshot.temperatureCelsius))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }

                InlineMetricRow(title: localized("metric.weather.highLow"), value: "\(temperatureText(snapshot.highCelsius)) / \(temperatureText(snapshot.lowCelsius))")
                InlineMetricRow(title: localized("metric.weather.feelsLike"), value: temperatureText(snapshot.feelsLikeCelsius))
                InlineMetricRow(title: localized("metric.weather.humidity"), value: "\(snapshot.humidityPercent)%")
                InlineMetricRow(title: localized("metric.weather.wind"), value: String(format: "%.0f km/h", snapshot.windKilometersPerHour))
                InlineMetricRow(title: localized("metric.weather.source"), value: snapshot.sourceName)

                if let precipitationChancePercent = snapshot.precipitationChancePercent {
                    InlineMetricRow(title: localized("metric.weather.rainChance"), value: "\(precipitationChancePercent)%")
                }

                Text(snapshot.nextRainSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let attribution = weatherStore.attribution {
                    HStack(spacing: 10) {
                        AsyncImage(url: colorScheme == .dark ? attribution.darkMarkURL : attribution.lightMarkURL) { phase in
                            switch phase {
                            case .empty:
                                Text(attribution.serviceName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                Text(attribution.serviceName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            @unknown default:
                                Text(attribution.serviceName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 120, height: 18, alignment: .leading)

                        Spacer()

                        Link(localized("weather.legal"), destination: attribution.legalPageURL)
                            .font(.caption)
                    }

                    DisclosureGroup(localized("weather.attribution.title")) {
                        Text(attribution.legalAttributionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Link(localized("weather.legal"), destination: attribution.legalPageURL)
                            .font(.caption.weight(.semibold))
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var networkCard: some View {
        DashboardCard(
            title: localized("card.network.title"),
            systemImage: "arrow.up.arrow.down.circle",
            description: localized("card.network.description")
        ) {
            HStack(alignment: .lastTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localized("metric.network.down"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rateText(store.snapshot.network.downloadRateBytesPerSecond))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localized("metric.network.up"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rateText(store.snapshot.network.uploadRateBytesPerSecond))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            }

            InlineMetricRow(title: localized("metric.network.activeInterfaces"), value: "\(store.snapshot.network.activeInterfaceCount)")
        }
    }

    private var dailyReportCard: some View {
        DashboardCard(
            title: localized("card.report.title"),
            systemImage: "calendar.badge.clock",
            description: localized("card.report.description")
        ) {
            if let report = store.todayReport {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text(percentageText(report.cpuPeakPercent))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    Text(localized("metric.report.cpuPeak"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                InlineMetricRow(title: localized("metric.report.cpuAverage"), value: percentageText(report.averageCPUPercent))
                InlineMetricRow(title: localized("metric.report.memoryPattern"), value: memoryPatternText(report))
                InlineMetricRow(title: localized("metric.report.batteryTrend"), value: batteryTrendText(report))
                InlineMetricRow(
                    title: localized("metric.report.networkPeak"),
                    value: "\(rateText(report.downloadPeakBytesPerSecond)) / \(rateText(report.uploadPeakBytesPerSecond))"
                )
                InlineMetricRow(title: localized("metric.report.window"), value: reportWindowText(report))
                InlineMetricRow(title: localized("metric.report.samples"), value: "\(report.sampleCount)")

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(localized("report.insights.title"))
                        .font(.callout.weight(.semibold))

                    ForEach(Array(store.dailyInsights.enumerated()), id: \.offset) { _, insight in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(insight)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text(localized("report.insight.collecting"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var powerCard: some View {
        DashboardCard(
            title: localized("card.battery.title"),
            systemImage: "battery.100",
            description: localized("card.battery.description")
        ) {
            if store.snapshot.battery.isAvailable {
                gaugeSection(
                    percent: store.snapshot.battery.chargePercent.map(Double.init),
                    tint: store.snapshot.battery.isCharging ? .green : .accentColor,
                    detail: nil
                )

                InlineMetricRow(title: localized("metric.battery.status"), value: batteryStatusText(store.snapshot.battery))
                InlineMetricRow(title: localized("metric.battery.source"), value: batterySourceText(store.snapshot.battery))
                InlineMetricRow(title: localized("metric.battery.timeRemaining"), value: batteryTimeRemainingText(store.snapshot.battery.timeRemainingMinutes))
                InlineMetricRow(title: localized("metric.lowPowerMode"), value: booleanText(store.snapshot.battery.lowPowerModeEnabled))
            } else {
                Text(localized("card.battery.noBattery"))
                    .foregroundStyle(.secondary)

                Divider()

                InlineMetricRow(title: localized("metric.lowPowerMode"), value: booleanText(store.snapshot.battery.lowPowerModeEnabled))
            }
        }
    }

    private var systemCard: some View {
        DashboardCard(
            title: localized("card.system.title"),
            systemImage: "laptopcomputer",
            description: localized("card.system.description")
        ) {
            Text(store.snapshot.hardware.marketingName)
                .font(.title3.weight(.semibold))

            InlineMetricRow(title: localized("metric.modelIdentifier"), value: store.snapshot.hardware.modelIdentifier)
            InlineMetricRow(title: localized("metric.chip"), value: store.snapshot.hardware.chipName)
            InlineMetricRow(title: localized("metric.coreLayout"), value: coreLayoutText(store.snapshot.hardware))
            InlineMetricRow(title: localized("metric.unifiedMemory"), value: byteCountString(store.snapshot.hardware.physicalMemoryBytes))
        }
    }

    private var storageCard: some View {
        DashboardCard(
            title: localized("card.storage.title"),
            systemImage: "internaldrive",
            description: localized("card.storage.description")
        ) {
            if let usagePercent = store.snapshot.storage.usagePercent {
                gaugeSection(
                    percent: usagePercent,
                    tint: usagePercent >= 85 ? .orange : .indigo,
                    detail: storageDetailText(store.snapshot.storage)
                )

                InlineMetricRow(title: localized("metric.volume"), value: store.snapshot.storage.volumeName)
                InlineMetricRow(title: localized("metric.used"), value: optionalGigabytesText(store.snapshot.storage.usedGB))
                InlineMetricRow(title: localized("metric.memory.available"), value: optionalGigabytesText(store.snapshot.storage.availableGB))
            } else {
                Text(localized("card.storage.unavailable"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activityCard: some View {
        DashboardCard(
            title: localized("card.activity.title"),
            systemImage: "speedometer",
            description: localized("card.activity.description")
        ) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(uptimeText(store.snapshot.activity.systemUptime))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text(localized("value.sinceBoot"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            InlineMetricRow(title: localized("metric.load1"), value: loadText(store.snapshot.activity.oneMinuteLoad))
            InlineMetricRow(title: localized("metric.load5"), value: loadText(store.snapshot.activity.fiveMinuteLoad))
            InlineMetricRow(title: localized("metric.load15"), value: loadText(store.snapshot.activity.fifteenMinuteLoad))
            InlineMetricRow(title: localized("metric.refresh"), value: String(format: "%.1fs", store.refreshInterval))

            Text(localized("activity.loadExplanation"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var perCoreCard: some View {
        DashboardCard(
            title: localized("card.perCore.title"),
            systemImage: "square.grid.3x3.topleft.filled",
            description: localized("card.perCore.description")
        ) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)],
                spacing: 12
            ) {
                ForEach(store.snapshot.cpu.perCore) { core in
                    CompactMetricMeter(
                        title: core.name,
                        subtitle: coreKindTitle(core.kind),
                        value: core.usagePercent,
                        tint: coreTint(core.kind)
                    )
                }
            }
        }
    }

    private var calendarCard: some View {
        DashboardCard(
            title: localized("card.calendar.title"),
            systemImage: "calendar",
            description: localized("card.calendar.description")
        ) {
            CalendarMonthPanel()
        }
    }

    private var trendsCard: some View {
        DashboardCard(
            title: localized("card.trends.title"),
            systemImage: "chart.line.uptrend.xyaxis",
            description: localized("card.trends.description")
        ) {
            VStack(spacing: 14) {
                TrendMetricRow(
                    title: localized("menu.summary.cpu"),
                    current: percentageText(store.snapshot.cpu.overallPercent),
                    peak: peakPercentText(store.cpuHistory),
                    values: store.cpuHistory,
                    tint: .accentColor
                )

                TrendMetricRow(
                    title: localized("menu.summary.memory"),
                    current: percentageText(store.snapshot.memory.usagePercent),
                    peak: peakPercentText(store.memoryHistory),
                    values: store.memoryHistory,
                    tint: memoryTint(for: store.snapshot.memory.pressure)
                )

                TrendMetricRow(
                    title: localized("metric.network.down"),
                    current: rateText(store.snapshot.network.downloadRateBytesPerSecond),
                    peak: peakRateText(store.downloadHistory),
                    values: store.downloadHistory,
                    tint: .blue
                )

                TrendMetricRow(
                    title: localized("metric.network.up"),
                    current: rateText(store.snapshot.network.uploadRateBytesPerSecond),
                    peak: peakRateText(store.uploadHistory),
                    values: store.uploadHistory,
                    tint: .green
                )
            }
        }
    }

    private func gaugeSection(percent: Double?, tint: Color, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(percentageText(percent))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Gauge(value: percent ?? 0, in: 0...100) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(tint)
        }
    }

    private func percentageText(_ value: Double?) -> String {
        guard let value else {
            return localized("value.calibrating")
        }

        return String(format: "%.0f%%", value)
    }

    private func temperatureText(_ value: Double) -> String {
        String(format: "%.0f°C", value)
    }

    private func gigabytesText(_ value: Double) -> String {
        String(format: "%.1f GB", value)
    }

    private func optionalGigabytesText(_ value: Double?) -> String {
        guard let value else {
            return localized("value.unavailable")
        }

        return gigabytesText(value)
    }

    private func byteCountString(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .memory)
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

    private func batteryStatusText(_ battery: BatterySnapshot) -> String {
        if battery.isCharging {
            return localized("battery.status.charging")
        }

        if battery.isPluggedIn {
            return localized("battery.status.ac")
        }

        return localized("battery.status.battery")
    }

    private func batterySourceText(_ battery: BatterySnapshot) -> String {
        guard let powerSource = battery.powerSource else {
            return localized("value.unavailable")
        }

        if powerSource == String(kIOPSACPowerValue) {
            return localized("power.source.ac")
        }

        if powerSource == String(kIOPSBatteryPowerValue) {
            return localized("power.source.battery")
        }

        return powerSource
    }

    private func batteryTimeRemainingText(_ minutes: Int?) -> String {
        guard let minutes else {
            return localized("value.unavailable")
        }

        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
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

    private func thermalDetail(for state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return localized("thermal.nominal.detail")
        case .fair:
            return localized("thermal.fair.detail")
        case .serious:
            return localized("thermal.serious.detail")
        case .critical:
            return localized("thermal.critical.detail")
        @unknown default:
            return localized("thermal.detail.unavailable")
        }
    }

    private func thermalWarningTitle(for level: ThermalWarningLevel) -> String {
        switch level {
        case .normal:
            return localized("thermal.warning.normal")
        case .warning:
            return localized("thermal.warning.warning")
        case .critical:
            return localized("thermal.warning.critical")
        case .unavailable:
            return localized("thermal.warning.unavailable")
        }
    }

    private func memoryPressureTitle(for pressure: MemoryPressureState) -> String {
        switch pressure {
        case .nominal:
            return localized("memory.pressure.nominal")
        case .warning:
            return localized("memory.pressure.warning")
        case .critical:
            return localized("memory.pressure.critical")
        }
    }

    private func memoryTint(for pressure: MemoryPressureState) -> Color {
        switch pressure {
        case .nominal:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private func coreKindTitle(_ kind: CPUCoreKind) -> String {
        switch kind {
        case .performance:
            return localized("core.kind.performance")
        case .efficiency:
            return localized("core.kind.efficiency")
        case .standard:
            return localized("core.kind.standard")
        }
    }

    private func coreTint(_ kind: CPUCoreKind) -> Color {
        switch kind {
        case .performance:
            return .pink
        case .efficiency:
            return .teal
        case .standard:
            return .accentColor
        }
    }

    private func booleanText(_ value: Bool) -> String {
        value ? localized("value.on") : localized("value.off")
    }

    private func coreLayoutText(_ hardware: HardwareSummary) -> String {
        switch (hardware.performanceCoreCount, hardware.efficiencyCoreCount) {
        case let (.some(performance), .some(efficiency)):
            return "\(hardware.logicalCoreCount) (\(performance)P / \(efficiency)E)"
        default:
            return "\(hardware.logicalCoreCount)"
        }
    }

    private func storageDetailText(_ storage: StorageSnapshot) -> String? {
        guard let usedGB = storage.usedGB, let totalGB = storage.totalGB else {
            return nil
        }

        return localizedFormat("storage.usage.detail", usedGB, totalGB)
    }

    private func storageBadgeText(_ storage: StorageSnapshot) -> String {
        guard let availableGB = storage.availableGB else {
            return localized("value.unavailable")
        }

        return localizedFormat("storage.free", availableGB)
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

    private func memoryPatternText(_ report: DailySystemReport) -> String {
        guard let averageMemoryPercent = report.averageMemoryPercent else {
            return localized("value.calibrating")
        }

        return localizedFormat("report.memory.pattern", averageMemoryPercent, report.memoryPeakPercent)
    }

    private func batteryTrendText(_ report: DailySystemReport) -> String {
        guard report.batteryStartPercent != nil else {
            return localized("report.battery.trend.unavailable")
        }

        if report.batteryDrainWhileOnBatteryPercent > 0 {
            return localizedFormat("report.battery.trend.discharge", report.batteryDrainWhileOnBatteryPercent)
        }

        if let startPercent = report.batteryStartPercent,
           let latestPercent = report.batteryLatestPercent,
           latestPercent > startPercent {
            return localizedFormat("report.battery.trend.charge", latestPercent - startPercent)
        }

        if report.batteryChargingSamples > report.batteryDischargingSamples {
            return localized("report.battery.trend.charging")
        }

        return localized("report.battery.trend.stable")
    }

    private func reportWindowText(_ report: DailySystemReport) -> String {
        guard report.monitoredDuration >= 60 else {
            return localized("report.window.pending")
        }

        return localizedFormat("report.window.tracked", uptimeText(report.monitoredDuration))
    }

    private func localized(_ key: String) -> String {
        AppStrings.localized(key)
    }

    private func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, arguments)
    }
}
