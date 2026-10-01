import Foundation

enum MemoryPressureState {
    case nominal
    case warning
    case critical
}

enum CPUCoreKind {
    case performance
    case efficiency
    case standard
}

enum ThermalWarningLevel {
    case normal
    case warning
    case critical
    case unavailable
}

struct HardwareSummary {
    let modelIdentifier: String
    let marketingName: String
    let chipName: String
    let logicalCoreCount: Int
    let performanceCoreCount: Int?
    let efficiencyCoreCount: Int?
    let physicalMemoryBytes: UInt64
}

struct CPUCoreSnapshot: Identifiable {
    let id: Int
    let name: String
    let kind: CPUCoreKind
    let usagePercent: Double?
}

struct CPUSnapshot {
    let overallPercent: Double?
    let performancePercent: Double?
    let efficiencyPercent: Double?
    let perCore: [CPUCoreSnapshot]
}

struct MemorySnapshot {
    let usagePercent: Double
    let usedGB: Double
    let totalGB: Double
    let availableGB: Double
    let appGB: Double
    let wiredGB: Double
    let compressedGB: Double
    let pressure: MemoryPressureState
}

struct BatterySnapshot {
    let isAvailable: Bool
    let chargePercent: Int?
    let isCharging: Bool
    let isPluggedIn: Bool
    let timeRemainingMinutes: Int?
    let health: String?
    let lowPowerModeEnabled: Bool

    static func unavailable(lowPowerModeEnabled: Bool) -> BatterySnapshot {
        BatterySnapshot(
            isAvailable: false,
            chargePercent: nil,
            isCharging: false,
            isPluggedIn: true,
            timeRemainingMinutes: nil,
            health: nil,
            lowPowerModeEnabled: lowPowerModeEnabled
        )
    }
}

struct NetworkSnapshot {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double

    static let empty = NetworkSnapshot(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
}

struct StorageSnapshot {
    let volumeName: String
    let usedBytes: Int64?
    let totalBytes: Int64?
    let availableBytes: Int64?

    var usagePercent: Double? {
        guard let usedBytes, let totalBytes, totalBytes > 0 else { return nil }
        return min(100, max(0, Double(usedBytes) / Double(totalBytes) * 100))
    }

    static let unavailable = StorageSnapshot(volumeName: "Startup Disk", usedBytes: nil, totalBytes: nil, availableBytes: nil)
}

struct ActivitySnapshot {
    let systemUptime: TimeInterval
    let oneMinuteLoad: Double?
    let fiveMinuteLoad: Double?
    let fifteenMinuteLoad: Double?
}

struct ThermalSnapshot {
    let state: ProcessInfo.ThermalState
    let warningLevel: ThermalWarningLevel

    var isElevated: Bool {
        state == .serious || state == .critical || warningLevel == .warning || warningLevel == .critical
    }
}

struct SystemSnapshot {
    let sampledAt: Date
    let hardware: HardwareSummary
    let cpu: CPUSnapshot
    let memory: MemorySnapshot
    let battery: BatterySnapshot
    let thermal: ThermalSnapshot
    let network: NetworkSnapshot
    let storage: StorageSnapshot
    let activity: ActivitySnapshot
}

/// One point in the rolling history that feeds the charts.
struct MetricSample: Identifiable {
    let date: Date
    let cpu: Double?
    let memory: Double
    let download: Double
    let upload: Double

    var id: Date { date }
    var memoryValue: Double? { memory }
}
