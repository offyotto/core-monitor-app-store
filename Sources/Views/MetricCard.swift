import Charts
import SwiftUI

// MARK: - Formatting

enum Format {
    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))%"
    }

    static func bytes(_ value: Int64?) -> String {
        guard let value else { return "—" }
        return ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    /// Memory uses binary units so a 16 GB Mac reads as 16 GB, matching About This Mac.
    static func gigabytes(_ value: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value * 1_073_741_824), countStyle: .memory)
    }

    private static let rateFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowsNonnumericFormatting = false
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter
    }()

    static func rate(_ bytesPerSecond: Double) -> String {
        rateFormatter.string(fromByteCount: Int64(max(0, bytesPerSecond))) + "/s"
    }

    static func duration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = interval >= 86_400 ? [.day, .hour] : [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? "—"
    }

    static func minutes(_ minutes: Int?) -> String {
        guard let minutes else { return "—" }
        return duration(TimeInterval(minutes * 60))
    }

    static func load(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.number.precision(.fractionLength(2)))
    }

    static func temperature(_ value: Measurement<UnitTemperature>?) -> String {
        guard let value else { return "—" }
        return value.formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}

// MARK: - Metric colors
// Each metric keeps one tint everywhere it appears, so color always means the same thing.

extension Color {
    static let cpuTint = Color.blue
    static let memoryTint = Color.purple
    static let storageTint = Color.indigo
    static let downloadTint = Color.teal
    static let uploadTint = Color.orange
    static let powerTint = Color.green
}

extension MemoryPressureState {
    var title: String {
        switch self {
        case .nominal: "Normal"
        case .warning: "Elevated"
        case .critical: "High"
        }
    }

    var color: Color {
        switch self {
        case .nominal: .green
        case .warning: .yellow
        case .critical: .red
        }
    }
}

extension ProcessInfo.ThermalState {
    var title: String {
        switch self {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }

    var detail: String {
        switch self {
        case .nominal: "Running normally."
        case .fair: "Slightly warm. Performance is unaffected."
        case .serious: "Hot. macOS may slow the system to cool it down."
        case .critical: "Very hot. macOS is reducing performance."
        @unknown default: "Thermal state is unavailable."
        }
    }

    var color: Color {
        switch self {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        @unknown default: .secondary
        }
    }
}

extension ThermalWarningLevel {
    var title: String {
        switch self {
        case .normal: "Normal"
        case .warning: "Warning"
        case .critical: "Critical"
        case .unavailable: "Not reported"
        }
    }
}

extension BatterySnapshot {
    var statusTitle: String {
        if isCharging { return "Charging" }
        if isPluggedIn { return "On power adapter" }
        return "On battery"
    }

    var symbolName: String {
        guard isAvailable, let chargePercent else { return "powerplug" }
        if isCharging { return "battery.100percent.bolt" }
        switch chargePercent {
        case 88...: return "battery.100percent"
        case 63..<88: return "battery.75percent"
        case 38..<63: return "battery.50percent"
        case 13..<38: return "battery.25percent"
        default: return "battery.0percent"
        }
    }
}

// MARK: - Charts

/// Charts always span the same three minutes, so a fresh launch fills in from the right
/// instead of stretching a few samples across the whole width.
func historyWindow(_ samples: [MetricSample]) -> ClosedRange<Date> {
    let end = samples.last?.date ?? Date()
    return end.addingTimeInterval(-180)...end
}

/// Small sparklines fit whatever history exists so they read well right after launch.
func fittedWindow(_ samples: [MetricSample]) -> ClosedRange<Date> {
    guard let first = samples.first?.date, let last = samples.last?.date, last > first else {
        return historyWindow(samples)
    }
    return first...last
}

struct PercentHistoryChart: View {
    let samples: [MetricSample]
    let value: KeyPath<MetricSample, Double?>
    let tint: Color
    var showsAxes = true

    var body: some View {
        Chart {
            ForEach(samples) { sample in
                if let y = sample[keyPath: value] {
                    AreaMark(x: .value("Time", sample.date), y: .value("Percent", y))
                        .foregroundStyle(tint.opacity(0.18))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Time", sample.date), y: .value("Percent", y))
                        .foregroundStyle(tint)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.monotone)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: showsAxes ? historyWindow(samples) : fittedWindow(samples))
        .chartXAxis(.hidden)
        .chartYAxis {
            if showsAxes {
                AxisMarks(position: .trailing, values: [0, 50, 100]) { mark in
                    AxisGridLine()
                    AxisValueLabel { Text("\(mark.as(Int.self) ?? 0)%") }
                }
            }
        }
        .accessibilityHidden(!showsAxes)
    }
}

struct NetworkHistoryChart: View {
    let samples: [MetricSample]
    var showsAxes = true

    var body: some View {
        Chart {
            ForEach(samples) { sample in
                LineMark(x: .value("Time", sample.date), y: .value("Rate", sample.download), series: .value("Direction", "Download"))
                    .foregroundStyle(Color.downloadTint)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", sample.date), y: .value("Rate", sample.upload), series: .value("Direction", "Upload"))
                    .foregroundStyle(Color.uploadTint)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.monotone)
            }
        }
        .chartXScale(domain: showsAxes ? historyWindow(samples) : fittedWindow(samples))
        .chartXAxis(.hidden)
        .chartYAxis {
            if showsAxes {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { mark in
                    AxisGridLine()
                    AxisValueLabel { Text(Format.rate(mark.as(Double.self) ?? 0)) }
                }
            }
        }
        .accessibilityHidden(!showsAxes)
    }
}

// MARK: - Layout pieces

/// The one card style in the app: a quiet filled rounded rectangle, no shadow.
struct Panel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.fill.quinary, in: .rect(cornerRadius: 12))
    }
}

struct SectionHeading: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

/// A large live value with its label, used at the top of each detail page.
struct HeadlineValue: View {
    let value: String
    let label: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// An icon and title with a fixed icon column, so rows with different symbols line up.
struct RowLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
        }
    }
}

struct UsageBar: View {
    let percent: Double?
    let tint: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.fill.tertiary)
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * CGFloat(min(max((percent ?? 0) / 100, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(.smooth(duration: 0.4), value: percent)
        .accessibilityHidden(true)
    }
}
