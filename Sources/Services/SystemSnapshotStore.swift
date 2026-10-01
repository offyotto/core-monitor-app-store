import Combine
import Foundation

enum SettingsKey {
    static let sampleInterval = "sampleInterval"
    static let weatherEnabled = "weatherEnabled"
    static let menuBarShowsCPU = "menuBarShowsCPU"
    static let menuBarShowsMemory = "menuBarShowsMemory"
    static let menuBarShowsNetwork = "menuBarShowsNetwork"
}

@MainActor
final class SystemSnapshotStore: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot
    @Published private(set) var history: [MetricSample] = []

    /// Three minutes of history at the default two-second interval.
    private let historyLimit = 90
    private let monitor = PublicSystemMonitor()
    private var timer: Timer?
    private var intervalObserver: AnyCancellable?

    init() {
        UserDefaults.standard.register(defaults: [SettingsKey.sampleInterval: 2.0])
        snapshot = monitor.sample()
        startTimer()

        intervalObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .compactMap { _ in UserDefaults.standard.double(forKey: SettingsKey.sampleInterval) }
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in self?.restartIfIntervalChanged() }
            }
    }

    private var interval: TimeInterval {
        let value = UserDefaults.standard.double(forKey: SettingsKey.sampleInterval)
        return value >= 1 ? value : 2
    }

    private func restartIfIntervalChanged() {
        guard let timer, timer.timeInterval != interval else { return }
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        timer.tolerance = interval * 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func sample() {
        let next = monitor.sample()
        snapshot = next
        history.append(
            MetricSample(
                date: next.sampledAt,
                cpu: next.cpu.overallPercent,
                memory: next.memory.usagePercent,
                download: next.network.downloadBytesPerSecond,
                upload: next.network.uploadBytesPerSecond
            )
        )
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}
