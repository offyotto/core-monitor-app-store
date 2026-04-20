import Combine
import Foundation

@MainActor
final class SystemSnapshotStore: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot
    @Published private(set) var cpuHistory: [Double] = []
    @Published private(set) var memoryHistory: [Double] = []
    @Published private(set) var downloadHistory: [Double] = []
    @Published private(set) var uploadHistory: [Double] = []
    @Published private(set) var dailyReports: [DailySystemReport] = []

    let refreshInterval: TimeInterval = 1.5

    private let monitor = PublicSystemMonitor()
    private let historyLimit = 60
    private let reportLimit = 14
    private let archiveURL: URL
    private var timer: Timer?

    init() {
        archiveURL = Self.makeArchiveURL()
        dailyReports = Self.loadReports(from: archiveURL)

        let initialSnapshot = monitor.sample()
        snapshot = initialSnapshot
        appendHistory(sample: initialSnapshot)
        recordDailySample(initialSnapshot)
        start()
    }

    deinit {
        timer?.invalidate()
    }

    var todayReport: DailySystemReport? {
        report(for: snapshot.sampledAt)
    }

    var yesterdayReport: DailySystemReport? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: snapshot.sampledAt) else {
            return nil
        }

        return report(for: yesterday)
    }

    var dailyInsights: [String] {
        guard let todayReport else {
            return [AppStrings.localized("report.insight.collecting")]
        }

        var insights: [String] = []

        if todayReport.sampleCount < 20 {
            insights.append(AppStrings.localized("report.insight.collecting"))
        }

        if todayReport.criticalThermalSamples > 0 {
            insights.append(AppStrings.localized("report.insight.thermal.critical"))
        } else if todayReport.seriousThermalSamples > 0 {
            insights.append(AppStrings.localized("report.insight.thermal.serious"))
        }

        if todayReport.cpuPeakPercent >= 85 {
            insights.append(AppStrings.format("report.insight.cpu.spike", Int(todayReport.cpuPeakPercent.rounded())))
        }

        if let averageMemoryPercent = todayReport.averageMemoryPercent, averageMemoryPercent >= 72 {
            insights.append(AppStrings.format("report.insight.memory.elevated", Int(averageMemoryPercent.rounded())))
        }

        if let batteryInsight = batteryInsight(today: todayReport, yesterday: yesterdayReport) {
            insights.append(batteryInsight)
        }

        if insights.isEmpty {
            insights.append(AppStrings.localized("report.insight.stable"))
        }

        return Array(insights.prefix(3))
    }

    func refreshNow() {
        let nextSnapshot = monitor.sample()
        snapshot = nextSnapshot
        appendHistory(sample: nextSnapshot)
        recordDailySample(nextSnapshot)
    }

    private func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
        timer?.tolerance = 0.4
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func appendHistory(sample: SystemSnapshot) {
        append(sample.cpu.overallPercent ?? 0, to: &cpuHistory)
        append(sample.memory.usagePercent, to: &memoryHistory)
        append(sample.network.downloadRateBytesPerSecond, to: &downloadHistory)
        append(sample.network.uploadRateBytesPerSecond, to: &uploadHistory)
    }

    private func recordDailySample(_ sample: SystemSnapshot) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: sample.sampledAt)

        if let index = dailyReports.firstIndex(where: { calendar.isDate($0.dayStart, inSameDayAs: dayStart) }) {
            dailyReports[index].record(sample: sample)
        } else {
            var report = DailySystemReport.empty(for: dayStart, sampledAt: sample.sampledAt)
            report.record(sample: sample)
            dailyReports.append(report)
        }

        dailyReports.sort { $0.dayStart < $1.dayStart }
        if dailyReports.count > reportLimit {
            dailyReports.removeFirst(dailyReports.count - reportLimit)
        }

        persistReports()
    }

    private func report(for date: Date) -> DailySystemReport? {
        dailyReports.last(where: { Calendar.current.isDate($0.dayStart, inSameDayAs: date) })
    }

    private func batteryInsight(today: DailySystemReport, yesterday: DailySystemReport?) -> String? {
        let todayDrain = today.batteryDrainWhileOnBatteryPercent
        guard todayDrain > 0 else { return nil }

        guard let yesterday, yesterday.batteryDrainWhileOnBatteryPercent >= 5 else {
            return nil
        }

        let yesterdayDrain = yesterday.batteryDrainWhileOnBatteryPercent
        let delta = Double(todayDrain - yesterdayDrain) / Double(yesterdayDrain)

        if delta >= 0.30 {
            return AppStrings.format("report.insight.battery.increased", Int((delta * 100).rounded()))
        }

        if delta <= -0.30 {
            return AppStrings.format("report.insight.battery.improved", Int((abs(delta) * 100).rounded()))
        }

        return nil
    }

    private func persistReports() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(dailyReports)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            // Ignore persistence failures; live metrics should continue to update.
        }
    }

    private func append(_ value: Double, to series: inout [Double]) {
        series.append(max(0, value))
        if series.count > historyLimit {
            series.removeFirst(series.count - historyLimit)
        }
    }

    private static func loadReports(from url: URL) -> [DailySystemReport] {
        guard let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([DailySystemReport].self, from: data)) ?? []
    }

    private static func makeArchiveURL() -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent("core-monitor", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent("daily-report-history.json")
    }
}
