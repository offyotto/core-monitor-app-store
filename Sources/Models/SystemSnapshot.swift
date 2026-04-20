import Foundation

enum AppStrings {
    private static let english: [String: String] = [
        "%@ unified memory • %@ • Uptime %@": "%1$@ unified memory • %2$@ • Uptime %3$@",
        "%@ • %@ • %@": "%1$@ • %2$@ • %3$@",
        "Apple Weather": "Apple Weather",
        "Core Monitor": "Core-Monitor",
        "Down": "Down",
        "Enable Location": "Enable Location",
        "Last updated": "Last updated",
        "Legal": "Legal",
        "Loading weather…": "Loading weather…",
        "Open Dashboard": "Open Dashboard",
        "Quit": "Quit",
        "Refresh": "Refresh",
        "Retry": "Retry",
        "System Overview": "System Overview",
        "Up": "Up",
        "activity.loadExplanation": "A load average near 1.0 roughly equals one fully busy logical core.",
        "app.name": "Core-Monitor",
        "badge.chip": "Chip",
        "badge.memory": "Memory",
        "badge.model": "Model",
        "battery.status.ac": "On power",
        "battery.status.battery": "On battery",
        "battery.status.charging": "Charging",
        "battery.summary.charging": "%d%% charging",
        "card.about.line1": "Sandboxed for signed distribution.",
        "card.about.line2": "Uses documented Apple frameworks.",
        "card.about.line3": "Focuses on read-only system status.",
        "card.about.title": "This Edition",
        "card.activity.description": "System uptime and load averages.",
        "card.activity.title": "Activity",
        "card.battery.description": "Battery status, charging state, and Low Power Mode.",
        "card.battery.noBattery": "No built-in battery is available on this Mac.",
        "card.battery.title": "Power",
        "card.calendar.description": "A quick month view for the current locale and time zone.",
        "card.calendar.title": "Calendar",
        "card.cpu.description": "Overall processor load with performance and efficiency split.",
        "card.cpu.title": "CPU Activity",
        "card.report.description": "Today's peaks, battery drift, and health insights from on-device monitoring.",
        "card.report.title": "Daily System Report",
        "card.memory.description": "Current memory use, compression, and headroom.",
        "card.memory.title": "Memory",
        "card.network.description": "Current transfer rates across active interfaces.",
        "card.network.title": "Network",
        "card.perCore.description": "Live load for each logical core.",
        "card.perCore.title": "Per-Core Activity",
        "card.storage.description": "Startup disk capacity and remaining space.",
        "card.storage.title": "Storage",
        "card.storage.unavailable": "Storage information is unavailable right now.",
        "card.system.description": "Resolved from the model identifier catalog and the chip name reported by macOS.",
        "card.system.title": "This Mac",
        "card.thermal.description": "System thermal pressure and warning level.",
        "card.thermal.title": "Thermal State",
        "card.trends.description": "Short rolling history for CPU, memory, and network activity.",
        "card.trends.title": "Recent Trends",
        "card.weather.description": "Live local conditions and short-range forecast.",
        "card.weather.title": "Weather",
        "core.kind.efficiency": "Efficiency",
        "core.kind.performance": "Performance",
        "core.kind.standard": "Logical Core",
        "dashboard.lastUpdated": "Last updated",
        "dashboard.readOnly": "Read-only monitoring. No helper. No fan control. No tracking.",
        "dashboard.subtitle": "CPU, thermal, memory, storage, network, weather, and power in one view.",
        "dashboard.title": "System Overview",
        "label.current": "Current",
        "label.peak": "Peak",
        "label.recentSamples": "Last 90 seconds",
        "link.privacyPolicy": "Privacy Policy",
        "link.support": "Support",
        "memory.pressure.critical": "High",
        "memory.pressure.nominal": "Normal",
        "memory.pressure.warning": "Elevated",
        "memory.usage.detail": "%.1f / %.1f GB",
        "menu.openDashboard": "Open Dashboard",
        "menu.quit": "Quit",
        "menu.refresh": "Refresh",
        "menu.section.trends": "Recent Trends",
        "menu.storage.free": "%.0f / %.0f GB free",
        "menu.subtitle.readOnly": "Read-only Mac App Store edition",
        "menu.summary.battery": "Battery",
        "menu.summary.cores": "Cores",
        "menu.summary.cpu": "CPU",
        "menu.summary.memory": "Memory",
        "menu.summary.storage": "Storage",
        "menu.summary.thermal": "Thermal",
        "menu.summary.uptime": "Uptime",
        "menu.title": "Core-Monitor",
        "metric.battery.source": "Source",
        "metric.battery.status": "Status",
        "metric.battery.timeRemaining": "Time remaining",
        "metric.chip": "Chip",
        "metric.coreLayout": "Core layout",
        "metric.efficiencyCores": "Efficiency cores",
        "metric.load1": "Load (1 min)",
        "metric.load1.short": "Load (1m)",
        "metric.load15": "Load (15 min)",
        "metric.load5": "Load (5 min)",
        "metric.lowPowerMode": "Low Power Mode",
        "metric.memory.app": "App memory",
        "metric.memory.available": "Available",
        "metric.memory.compressed": "Compressed",
        "metric.memory.pressure": "Pressure",
        "metric.memory.wired": "Wired memory",
        "metric.modelIdentifier": "Model identifier",
        "metric.network.activeInterfaces": "Active interfaces",
        "metric.network.down": "Down",
        "metric.network.up": "Up",
        "metric.performanceCores": "Performance cores",
        "metric.refresh": "Refresh",
        "metric.report.batteryTrend": "Battery trend",
        "metric.report.cpuAverage": "Avg CPU",
        "metric.report.cpuPeak": "Peak CPU",
        "metric.report.memoryPattern": "Memory pattern",
        "metric.report.networkPeak": "Peak network",
        "metric.report.samples": "Samples",
        "metric.report.window": "Window",
        "metric.thermal.state": "Thermal state",
        "metric.thermal.status": "Status",
        "metric.thermal.warning": "Warning level",
        "metric.totalCores": "Total cores",
        "metric.unifiedMemory": "Unified memory",
        "metric.used": "Used",
        "metric.volume": "Volume",
        "metric.weather.feelsLike": "Feels like",
        "metric.weather.highLow": "High / Low",
        "metric.weather.humidity": "Humidity",
        "metric.weather.rainChance": "Rain chance",
        "metric.weather.source": "Source",
        "metric.weather.wind": "Wind",
        "power.source.ac": "AC power",
        "power.source.battery": "Battery",
        "report.battery.trend.charge": "+%d%% while charging",
        "report.battery.trend.charging": "Charging and recovering",
        "report.battery.trend.discharge": "-%d%% on battery",
        "report.battery.trend.stable": "Stable",
        "report.battery.trend.unavailable": "No battery data yet",
        "report.insight.battery.improved": "Battery drain is down %d%% versus yesterday.",
        "report.insight.battery.increased": "Battery drain is up %d%% versus yesterday.",
        "report.insight.collecting": "Collecting today's baseline.",
        "report.insight.cpu.spike": "CPU peaked at %d%% today.",
        "report.insight.memory.elevated": "Memory averaged %d%% today.",
        "report.insight.stable": "System trends look stable so far.",
        "report.insight.thermal.critical": "Thermal pressure reached a critical state today.",
        "report.insight.thermal.serious": "Thermal pressure reached a serious state today.",
        "report.insights.title": "Health insights",
        "report.memory.pattern": "Avg %.0f%% • Peak %.0f%%",
        "report.window.pending": "Starting now",
        "report.window.tracked": "%@ monitored",
        "since boot": "since boot",
        "storage.free": "%.0f GB free",
        "storage.usage.detail": "%.0f / %.0f GB",
        "thermal.critical.detail": "The system is under heavy thermal stress.",
        "thermal.critical.title": "Critical",
        "thermal.detail.unavailable": "Thermal status is unavailable.",
        "thermal.fair.detail": "Thermals are elevated but stable.",
        "thermal.fair.title": "Fair",
        "thermal.nominal.detail": "Thermals are within the normal operating range.",
        "thermal.nominal.title": "Nominal",
        "thermal.publicAPI.note": "macOS does not publish an exact CPU temperature reading to third-party apps, so this card uses the system thermal signals Apple exposes.",
        "thermal.serious.detail": "macOS is likely reducing performance to cool the system.",
        "thermal.serious.title": "Serious",
        "thermal.warning.critical": "Critical",
        "thermal.warning.normal": "Normal",
        "thermal.warning.unavailable": "Unavailable",
        "thermal.warning.warning": "Warning",
        "value.calibrating": "Calibrating",
        "value.off": "Off",
        "value.on": "On",
        "value.sinceBoot": "since boot",
        "value.unavailable": "Unavailable",
        "weather.condition.clear": "Clear",
        "weather.condition.drizzle": "Drizzle",
        "weather.condition.fog": "Fog",
        "weather.condition.mainlyClear": "Mainly Clear",
        "weather.condition.overcast": "Overcast",
        "weather.condition.partlyCloudy": "Partly Cloudy",
        "weather.condition.rain": "Rain",
        "weather.condition.snow": "Snow",
        "weather.condition.thunderstorm": "Thunderstorm",
        "weather.condition.weather": "Weather",
        "weather.enable.body": "Core-Monitor requires your location to display local weather.",
        "weather.enable.button": "Enable Location",
        "weather.enable.title": "Enable location to show local weather.",
        "weather.attribution.title": "Sources & Legal",
        "weather.legal": "Legal",
        "weather.loading": "Loading weather…",
        "weather.location.local": "Local Weather",
        "weather.rain.active": "Rain is active now.",
        "weather.rain.chance": "%d%% rain chance %@.",
        "weather.rain.expected": "Rain expected %@.",
        "weather.rain.none": "No rain expected soon.",
        "weather.retry": "Retry",
        "weather.source.apple": "Apple Weather",
        "weather.status.locationNeeded": "Location needed",
        "weather.status.locationOff": "Location off",
        "weather.status.needsSignedBuild": "Needs signed build",
        "weather.status.setupRequired": "Setup required",
        "weather.status.updating": "Updating",
        "weather.unavailable.generic": "Weather is unavailable right now.",
        "weather.unavailable.locationAccess": "Location access is off. Enable it in System Settings to display the weather.",
        "weather.unavailable.locationRequired": "Core-Monitor requires your location to display local weather.",
        "weather.unavailable.network": "Apple Weather couldn't be reached right now. Check the network connection and try again.",
        "weather.unavailable.signedBuild": "Weather needs the WeatherKit capability in a signed build.",
        "weather.unavailable.setupRequired": "WeatherKit couldn't authenticate this build. Enable WeatherKit for this App ID in Certificates, Identifiers & Profiles, then refresh the provisioning profile.",
    ]

    static func localized(_ key: String) -> String {
        let value = NSLocalizedString(key, comment: "")
        if value != key {
            return value
        }
        return english[key] ?? key
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: Locale.current, arguments: arguments)
    }

    static func format(_ key: String, arguments: [CVarArg]) -> String {
        String(format: localized(key), locale: Locale.current, arguments: arguments)
    }
}

enum AppExternalLinks {
    static let privacyPolicy = URL(string: "https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/privacy/")!
    static let support = URL(string: "https://offyotto-sl3.github.io/Core-Monitor/Mac-App-Store/support/")!
}

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
    let powerSource: String?
    let timeRemainingMinutes: Int?
    let lowPowerModeEnabled: Bool

    static func unavailable(lowPowerModeEnabled: Bool) -> BatterySnapshot {
        BatterySnapshot(
            isAvailable: false,
            chargePercent: nil,
            isCharging: false,
            isPluggedIn: false,
            powerSource: nil,
            timeRemainingMinutes: nil,
            lowPowerModeEnabled: lowPowerModeEnabled
        )
    }
}

struct NetworkSnapshot {
    let downloadRateBytesPerSecond: Double
    let uploadRateBytesPerSecond: Double
    let activeInterfaceCount: Int

    static let empty = NetworkSnapshot(
        downloadRateBytesPerSecond: 0,
        uploadRateBytesPerSecond: 0,
        activeInterfaceCount: 0
    )
}

struct StorageSnapshot {
    let volumeName: String
    let usagePercent: Double?
    let usedGB: Double?
    let totalGB: Double?
    let availableGB: Double?

    static let unavailable = StorageSnapshot(
        volumeName: "Startup Disk",
        usagePercent: nil,
        usedGB: nil,
        totalGB: nil,
        availableGB: nil
    )
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
}

struct DailySystemReport: Codable, Identifiable {
    let dayStart: Date
    var firstSampleAt: Date
    var lastSampleAt: Date
    var sampleCount: Int
    var cpuPeakPercent: Double
    var cpuTotalPercent: Double
    var cpuSampleCount: Int
    var memoryPeakPercent: Double
    var memoryTotalPercent: Double
    var memorySampleCount: Int
    var downloadPeakBytesPerSecond: Double
    var uploadPeakBytesPerSecond: Double
    var batteryStartPercent: Int?
    var batteryLatestPercent: Int?
    var batteryDrainWhileOnBatteryPercent: Int
    var batteryDischargingSamples: Int
    var batteryChargingSamples: Int
    var batteryLowPercent: Int?
    var batteryHighPercent: Int?
    var lastBatteryPercent: Int?
    var lastBatteryWasDischarging: Bool
    var seriousThermalSamples: Int
    var criticalThermalSamples: Int

    var id: Date { dayStart }

    var averageCPUPercent: Double? {
        guard cpuSampleCount > 0 else { return nil }
        return cpuTotalPercent / Double(cpuSampleCount)
    }

    var averageMemoryPercent: Double? {
        guard memorySampleCount > 0 else { return nil }
        return memoryTotalPercent / Double(memorySampleCount)
    }

    var monitoredDuration: TimeInterval {
        max(lastSampleAt.timeIntervalSince(firstSampleAt), 0)
    }

    static func empty(for dayStart: Date, sampledAt: Date) -> DailySystemReport {
        DailySystemReport(
            dayStart: dayStart,
            firstSampleAt: sampledAt,
            lastSampleAt: sampledAt,
            sampleCount: 0,
            cpuPeakPercent: 0,
            cpuTotalPercent: 0,
            cpuSampleCount: 0,
            memoryPeakPercent: 0,
            memoryTotalPercent: 0,
            memorySampleCount: 0,
            downloadPeakBytesPerSecond: 0,
            uploadPeakBytesPerSecond: 0,
            batteryStartPercent: nil,
            batteryLatestPercent: nil,
            batteryDrainWhileOnBatteryPercent: 0,
            batteryDischargingSamples: 0,
            batteryChargingSamples: 0,
            batteryLowPercent: nil,
            batteryHighPercent: nil,
            lastBatteryPercent: nil,
            lastBatteryWasDischarging: false,
            seriousThermalSamples: 0,
            criticalThermalSamples: 0
        )
    }

    mutating func record(sample: SystemSnapshot) {
        if sampleCount == 0 {
            firstSampleAt = sample.sampledAt
        }

        lastSampleAt = sample.sampledAt
        sampleCount += 1

        if let cpuPercent = sample.cpu.overallPercent {
            cpuPeakPercent = max(cpuPeakPercent, cpuPercent)
            cpuTotalPercent += cpuPercent
            cpuSampleCount += 1
        }

        memoryPeakPercent = max(memoryPeakPercent, sample.memory.usagePercent)
        memoryTotalPercent += sample.memory.usagePercent
        memorySampleCount += 1

        downloadPeakBytesPerSecond = max(downloadPeakBytesPerSecond, sample.network.downloadRateBytesPerSecond)
        uploadPeakBytesPerSecond = max(uploadPeakBytesPerSecond, sample.network.uploadRateBytesPerSecond)

        switch sample.thermal.state {
        case .serious:
            seriousThermalSamples += 1
        case .critical:
            criticalThermalSamples += 1
        default:
            break
        }

        guard sample.battery.isAvailable, let chargePercent = sample.battery.chargePercent else {
            lastBatteryPercent = nil
            lastBatteryWasDischarging = false
            return
        }

        if batteryStartPercent == nil {
            batteryStartPercent = chargePercent
        }

        batteryLatestPercent = chargePercent
        batteryLowPercent = min(batteryLowPercent ?? chargePercent, chargePercent)
        batteryHighPercent = max(batteryHighPercent ?? chargePercent, chargePercent)

        let isDischarging = sample.battery.isCharging == false && sample.battery.isPluggedIn == false
        if isDischarging {
            batteryDischargingSamples += 1
            if let lastBatteryPercent, lastBatteryWasDischarging, chargePercent < lastBatteryPercent {
                batteryDrainWhileOnBatteryPercent += (lastBatteryPercent - chargePercent)
            }
        } else {
            batteryChargingSamples += 1
        }

        lastBatteryPercent = chargePercent
        lastBatteryWasDischarging = isDischarging
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

    var menuBarTitle: String {
        var segments = [
            menuPercent("CPU", cpu.overallPercent),
            menuPercent("RAM", memory.usagePercent)
        ]

        if network.downloadRateBytesPerSecond >= 12_288 {
            segments.append("↓\(menuRate(network.downloadRateBytesPerSecond))")
        }

        if network.uploadRateBytesPerSecond >= 12_288 {
            segments.append("↑\(menuRate(network.uploadRateBytesPerSecond))")
        }

        if thermal.state == .serious || thermal.state == .critical
            || thermal.warningLevel == .warning || thermal.warningLevel == .critical {
            segments.append("HOT")
        }

        return segments.joined(separator: " ")
    }

    private func menuPercent(_ label: String, _ value: Double?) -> String {
        guard let value else {
            return "\(label) --"
        }

        return "\(label) \(String(format: "%.0f%%", value))"
    }

    private func menuRate(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1_073_741_824 {
            return String(format: "%.1fG", bytesPerSecond / 1_073_741_824)
        }

        if bytesPerSecond >= 1_048_576 {
            return String(format: "%.1fM", bytesPerSecond / 1_048_576)
        }

        return String(format: "%.0fK", bytesPerSecond / 1_024)
    }
}
