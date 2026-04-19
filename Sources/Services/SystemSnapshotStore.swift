import Foundation
import Combine

@MainActor
final class SystemSnapshotStore: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot
    @Published private(set) var cpuHistory: [Double] = []
    @Published private(set) var memoryHistory: [Double] = []
    @Published private(set) var downloadHistory: [Double] = []
    @Published private(set) var uploadHistory: [Double] = []

    let refreshInterval: TimeInterval = 1.5

    private let monitor = PublicSystemMonitor()
    private var timer: Timer?
    private let historyLimit = 60

    init() {
        let initialSnapshot = monitor.sample()
        snapshot = initialSnapshot
        appendHistory(sample: initialSnapshot)
        start()
    }

    deinit {
        timer?.invalidate()
    }

    func refreshNow() {
        let nextSnapshot = monitor.sample()
        snapshot = nextSnapshot
        appendHistory(sample: nextSnapshot)
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

    private func append(_ value: Double, to series: inout [Double]) {
        series.append(max(0, value))
        if series.count > historyLimit {
            series.removeFirst(series.count - historyLimit)
        }
    }
}
