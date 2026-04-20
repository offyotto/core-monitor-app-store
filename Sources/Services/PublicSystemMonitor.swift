import Foundation
import IOKit.ps
import Darwin

final class PublicSystemMonitor {
    private let hardware: HardwareSummary

    private var previousCPULoadInfo = host_cpu_load_info_data_t()
    private var hasPreviousCPUSample = false
    private var previousProcessorLoadInfo: [integer_t] = []
    private var hasPreviousProcessorSample = false
    private var previousNetworkCounters: NetworkCounters?

    init() {
        let modelIdentifier = Self.sysctlString(named: "hw.model") ?? "Mac"
        let catalogEntry = AppleSiliconMacCatalog.entry(for: modelIdentifier)

        hardware = HardwareSummary(
            modelIdentifier: modelIdentifier,
            marketingName: catalogEntry?.marketingName ?? modelIdentifier,
            chipName: Self.chipName(
                modelIdentifier: modelIdentifier,
                fallbackChipName: catalogEntry?.chipFamilyName
            ),
            logicalCoreCount: ProcessInfo.processInfo.activeProcessorCount,
            performanceCoreCount: nil,
            efficiencyCoreCount: nil,
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory
        )
    }

    func sample() -> SystemSnapshot {
        let sampledAt = Date()

        return SystemSnapshot(
            sampledAt: sampledAt,
            hardware: hardware,
            cpu: sampleCPU(),
            memory: sampleMemory(),
            battery: sampleBattery(),
            thermal: sampleThermal(),
            network: sampleNetwork(sampledAt: sampledAt),
            storage: sampleStorage(),
            activity: sampleActivity()
        )
    }

    private func sampleCPU() -> CPUSnapshot {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &loadInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }

        let breakdown = sampleCPUCoreBreakdown()

        guard result == KERN_SUCCESS else {
            return CPUSnapshot(
                overallPercent: nil,
                performancePercent: breakdown.performancePercent,
                efficiencyPercent: breakdown.efficiencyPercent,
                perCore: breakdown.perCore
            )
        }

        guard hasPreviousCPUSample else {
            previousCPULoadInfo = loadInfo
            hasPreviousCPUSample = true
            return CPUSnapshot(
                overallPercent: nil,
                performancePercent: breakdown.performancePercent,
                efficiencyPercent: breakdown.efficiencyPercent,
                perCore: breakdown.perCore
            )
        }

        let user = Double(loadInfo.cpu_ticks.0 - previousCPULoadInfo.cpu_ticks.0)
        let system = Double(loadInfo.cpu_ticks.1 - previousCPULoadInfo.cpu_ticks.1)
        let idle = Double(loadInfo.cpu_ticks.2 - previousCPULoadInfo.cpu_ticks.2)
        let nice = Double(loadInfo.cpu_ticks.3 - previousCPULoadInfo.cpu_ticks.3)
        previousCPULoadInfo = loadInfo

        let total = user + system + idle + nice
        let overallPercent: Double?
        if total > 0 {
            overallPercent = min(100, max(0, ((user + system + nice) / total) * 100))
        } else {
            overallPercent = nil
        }

        return CPUSnapshot(
            overallPercent: overallPercent,
            performancePercent: breakdown.performancePercent,
            efficiencyPercent: breakdown.efficiencyPercent,
            perCore: breakdown.perCore
        )
    }

    private func sampleCPUCoreBreakdown() -> (performancePercent: Double?, efficiencyPercent: Double?, perCore: [CPUCoreSnapshot]) {
        var processorInfo: processor_info_array_t?
        var processorInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            processor_flavor_t(PROCESSOR_CPU_LOAD_INFO),
            &processorCount,
            &processorInfo,
            &processorInfoCount
        )

        guard result == KERN_SUCCESS, let processorInfo else {
            return (nil, nil, [])
        }

        defer {
            let byteCount = vm_size_t(Int(processorInfoCount) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: processorInfo), byteCount)
        }

        let sample = Array(UnsafeBufferPointer(start: processorInfo, count: Int(processorInfoCount)))
        let cpuCount = Int(processorCount)
        guard cpuCount > 0, sample.count >= cpuCount * Int(CPU_STATE_MAX) else {
            return (nil, nil, [])
        }

        guard hasPreviousProcessorSample, previousProcessorLoadInfo.count == sample.count else {
            previousProcessorLoadInfo = sample
            hasPreviousProcessorSample = true
            return (nil, nil, emptyPerCoreUsage(cpuCount: cpuCount))
        }

        defer { previousProcessorLoadInfo = sample }

        var perCore: [CPUCoreSnapshot] = []
        var performanceSamples: [Double] = []
        var efficiencySamples: [Double] = []
        var performanceIndex = 0
        var efficiencyIndex = 0
        var standardIndex = 0

        for processor in 0..<cpuCount {
            let usage = usageForProcessor(processor: processor, current: sample, previous: previousProcessorLoadInfo)
            let kind = coreKind(for: processor)
            let title: String

            switch kind {
            case .performance:
                performanceIndex += 1
                title = "P\(performanceIndex)"
                if let usage {
                    performanceSamples.append(usage)
                }
            case .efficiency:
                efficiencyIndex += 1
                title = "E\(efficiencyIndex)"
                if let usage {
                    efficiencySamples.append(usage)
                }
            case .standard:
                standardIndex += 1
                title = "Core \(standardIndex)"
            }

            perCore.append(
                CPUCoreSnapshot(
                    id: processor,
                    name: title,
                    kind: kind,
                    usagePercent: usage
                )
            )
        }

        return (average(performanceSamples), average(efficiencySamples), perCore)
    }

    private func usageForProcessor(
        processor: Int,
        current: [integer_t],
        previous: [integer_t]
    ) -> Double? {
        let stride = Int(CPU_STATE_MAX)
        let base = processor * stride

        let user = max(0, Int(current[base + Int(CPU_STATE_USER)] - previous[base + Int(CPU_STATE_USER)]))
        let system = max(0, Int(current[base + Int(CPU_STATE_SYSTEM)] - previous[base + Int(CPU_STATE_SYSTEM)]))
        let idle = max(0, Int(current[base + Int(CPU_STATE_IDLE)] - previous[base + Int(CPU_STATE_IDLE)]))
        let nice = max(0, Int(current[base + Int(CPU_STATE_NICE)] - previous[base + Int(CPU_STATE_NICE)]))

        let used = Double(user + system + nice)
        let total = Double(user + system + idle + nice)
        guard total > 0 else { return nil }
        return min(100, max(0, (used / total) * 100))
    }

    private func sampleMemory() -> MemorySnapshot {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }

        let totalBytes = Double(hardware.physicalMemoryBytes)
        guard result == KERN_SUCCESS, totalBytes > 0 else {
            return MemorySnapshot(
                usagePercent: 0,
                usedGB: 0,
                totalGB: totalBytes / 1_073_741_824.0,
                availableGB: 0,
                appGB: 0,
                wiredGB: 0,
                compressedGB: 0,
                pressure: .nominal
            )
        }

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let page = Double(pageSize)

        let appBytes = Double(stats.active_count) * page
        let wiredBytes = Double(stats.wire_count) * page
        let compressedBytes = Double(stats.compressor_page_count) * page
        let usedBytes = appBytes + wiredBytes + compressedBytes
        let availableBytes = max(0, totalBytes - usedBytes)
        let usagePercent = min(100, max(0, (usedBytes / totalBytes) * 100))
        let availableRatio = availableBytes / totalBytes

        let pressure: MemoryPressureState
        if availableRatio > 0.25 {
            pressure = .nominal
        } else if availableRatio > 0.12 {
            pressure = .warning
        } else {
            pressure = .critical
        }

        return MemorySnapshot(
            usagePercent: usagePercent,
            usedGB: usedBytes / 1_073_741_824.0,
            totalGB: totalBytes / 1_073_741_824.0,
            availableGB: availableBytes / 1_073_741_824.0,
            appGB: appBytes / 1_073_741_824.0,
            wiredGB: wiredBytes / 1_073_741_824.0,
            compressedGB: compressedBytes / 1_073_741_824.0,
            pressure: pressure
        )
    }

    private func sampleBattery() -> BatterySnapshot {
        let lowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return .unavailable(lowPowerModeEnabled: lowPowerModeEnabled)
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int
        let max = description[kIOPSMaxCapacityKey as String] as? Int
        let chargePercent: Int?
        if let current, let max, max > 0 {
            chargePercent = Int((Double(current) / Double(max) * 100.0).rounded())
        } else {
            chargePercent = nil
        }

        let isCharging = (description[kIOPSIsChargingKey as String] as? Bool) ?? false
        let powerSource = description[kIOPSPowerSourceStateKey as String] as? String
        let isPluggedIn = powerSource == (kIOPSACPowerValue as String)

        let timeRemaining: Int?
        if let minutes = description[kIOPSTimeToEmptyKey as String] as? Int, minutes >= 0 {
            timeRemaining = minutes
        } else if let minutes = description[kIOPSTimeToFullChargeKey as String] as? Int, minutes >= 0 {
            timeRemaining = minutes
        } else {
            timeRemaining = nil
        }

        return BatterySnapshot(
            isAvailable: true,
            chargePercent: chargePercent,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            powerSource: powerSource,
            timeRemainingMinutes: timeRemaining,
            lowPowerModeEnabled: lowPowerModeEnabled
        )
    }

    private func sampleThermal() -> ThermalSnapshot {
        return ThermalSnapshot(
            state: ProcessInfo.processInfo.thermalState,
            warningLevel: .unavailable
        )
    }

    private func sampleNetwork(sampledAt: Date) -> NetworkSnapshot {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacePointer) == 0, let firstInterface = interfacePointer else {
            return .empty
        }
        defer { freeifaddrs(interfacePointer) }

        var receivedBytes: UInt64 = 0
        var transmittedBytes: UInt64 = 0
        var activeInterfaceCount = 0

        for interface in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            guard let address = interface.pointee.ifa_addr else { continue }
            guard address.pointee.sa_family == UInt8(AF_LINK) else { continue }

            let flags = Int32(interface.pointee.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let data = interface.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) else { continue }

            receivedBytes += UInt64(data.pointee.ifi_ibytes)
            transmittedBytes += UInt64(data.pointee.ifi_obytes)
            activeInterfaceCount += 1
        }

        let counters = NetworkCounters(
            receivedBytes: receivedBytes,
            transmittedBytes: transmittedBytes,
            sampledAt: sampledAt
        )

        guard let previousNetworkCounters else {
            self.previousNetworkCounters = counters
            return .empty
        }

        self.previousNetworkCounters = counters

        let elapsed = max(sampledAt.timeIntervalSince(previousNetworkCounters.sampledAt), 0.5)
        let receivedDelta = receivedBytes >= previousNetworkCounters.receivedBytes
            ? receivedBytes - previousNetworkCounters.receivedBytes
            : 0
        let transmittedDelta = transmittedBytes >= previousNetworkCounters.transmittedBytes
            ? transmittedBytes - previousNetworkCounters.transmittedBytes
            : 0

        return NetworkSnapshot(
            downloadRateBytesPerSecond: Double(receivedDelta) / elapsed,
            uploadRateBytesPerSecond: Double(transmittedDelta) / elapsed,
            activeInterfaceCount: activeInterfaceCount
        )
    }

    private func sampleStorage() -> StorageSnapshot {
        var fileSystem = statfs()
        let result = "/".withCString { path in
            statfs(path, &fileSystem)
        }

        guard result == 0 else {
            return .unavailable
        }

        let blockSize = UInt64(fileSystem.f_bsize)
        let totalBytes = UInt64(fileSystem.f_blocks) * blockSize
        let availableBytes = UInt64(fileSystem.f_bavail) * blockSize
        let usedBytes = totalBytes > availableBytes ? totalBytes - availableBytes : 0
        let usagePercent: Double? = totalBytes > 0
            ? min(100, max(0, (Double(usedBytes) / Double(totalBytes)) * 100))
            : nil

        let volumeName = (try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeNameKey]).volumeName)
            ?? "Startup Disk"

        return StorageSnapshot(
            volumeName: volumeName,
            usagePercent: usagePercent,
            usedGB: Double(usedBytes) / 1_073_741_824.0,
            totalGB: Double(totalBytes) / 1_073_741_824.0,
            availableGB: Double(availableBytes) / 1_073_741_824.0
        )
    }

    private func sampleActivity() -> ActivitySnapshot {
        var values = [Double](repeating: 0, count: 3)
        let result = values.withUnsafeMutableBufferPointer { buffer in
            getloadavg(buffer.baseAddress, Int32(buffer.count))
        }

        return ActivitySnapshot(
            systemUptime: ProcessInfo.processInfo.systemUptime,
            oneMinuteLoad: result > 0 ? values[0] : nil,
            fiveMinuteLoad: result > 1 ? values[1] : nil,
            fifteenMinuteLoad: result > 2 ? values[2] : nil
        )
    }

    private func coreKind(for processor: Int) -> CPUCoreKind {
        if let performanceCoreCount = hardware.performanceCoreCount, processor < performanceCoreCount {
            return .performance
        }

        if let performanceCoreCount = hardware.performanceCoreCount,
           let efficiencyCoreCount = hardware.efficiencyCoreCount,
           processor < performanceCoreCount + efficiencyCoreCount {
            return .efficiency
        }

        return .standard
    }

    private func average(_ values: [Double]) -> Double? {
        guard values.isEmpty == false else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func emptyPerCoreUsage(cpuCount: Int) -> [CPUCoreSnapshot] {
        var performanceIndex = 0
        var efficiencyIndex = 0
        var standardIndex = 0

        return (0..<cpuCount).map { processor in
            let kind = coreKind(for: processor)
            let name: String

            switch kind {
            case .performance:
                performanceIndex += 1
                name = "P\(performanceIndex)"
            case .efficiency:
                efficiencyIndex += 1
                name = "E\(efficiencyIndex)"
            case .standard:
                standardIndex += 1
                name = "Core \(standardIndex)"
            }

            return CPUCoreSnapshot(id: processor, name: name, kind: kind, usagePercent: nil)
        }
    }

    private static func chipName(modelIdentifier: String, fallbackChipName: String?) -> String {
        if let fallbackChipName, fallbackChipName.isEmpty == false {
            return fallbackChipName
        }

        return modelIdentifier
    }

    private static func sysctlString(named name: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }
}

private struct NetworkCounters {
    let receivedBytes: UInt64
    let transmittedBytes: UInt64
    let sampledAt: Date
}
