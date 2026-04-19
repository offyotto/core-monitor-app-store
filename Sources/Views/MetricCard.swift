import SwiftUI

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    let description: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct InlineMetricRow: View {
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
        .font(.callout)
    }
}

struct CompactMetricMeter: View {
    let title: String
    let subtitle: String
    let value: Double?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(valueText)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
            }

            ProgressView(value: value ?? 0, total: 100)
                .tint(tint)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var valueText: String {
        guard let value else {
            return "--"
        }

        return String(format: "%.0f%%", value)
    }
}

struct TrendMetricRow: View {
    let title: String
    let current: String
    let peak: String
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.callout.weight(.semibold))

                Spacer()

                Text(current)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
            }

            TrendSparkline(values: values, tint: tint)

            HStack {
                Text(AppStrings.localized("label.recentSamples"))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(AppStrings.localized("label.peak")) \(peak)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.caption)
        }
    }
}

struct TrendSparkline: View {
    let values: [Double]
    let tint: Color
    var height: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints(in: geometry.size)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.08))

                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
                        for point in points {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.25), tint.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                } else {
                    Rectangle()
                        .fill(tint.opacity(0.35))
                        .frame(height: 2)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.isEmpty == false else { return [] }
        guard values.count > 1 else {
            return [CGPoint(x: 0, y: size.height / 2)]
        }

        let minimum = values.min() ?? 0
        let maximum = values.max() ?? minimum
        let span = max(maximum - minimum, 0.0001)
        let widthStep = size.width / CGFloat(max(values.count - 1, 1))
        let inset: CGFloat = 2
        let usableHeight = max(size.height - (inset * 2), 1)

        return values.enumerated().map { index, value in
            let normalized = (value - minimum) / span
            let x = CGFloat(index) * widthStep
            let y = inset + (usableHeight * CGFloat(1 - normalized))
            return CGPoint(x: x, y: y)
        }
    }
}

struct CalendarMonthPanel: View {
    var referenceDate: Date = .now

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(referenceDate.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)

                    Text(referenceDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(TimeZone.current.localizedName(for: .shortStandard, locale: .current) ?? TimeZone.current.identifier)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(days, id: \.date) { day in
                    dayCell(day)
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    private var days: [CalendarMonthDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: referenceDate),
            let daysRange = calendar.range(of: .day, in: .month, for: monthInterval.start)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingDayCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        let totalDayCount = daysRange.count
        let trailingDayCount = (7 - ((leadingDayCount + totalDayCount) % 7)) % 7

        return (0..<(leadingDayCount + totalDayCount + trailingDayCount)).compactMap { index in
            guard let date = calendar.date(byAdding: .day, value: index - leadingDayCount, to: monthInterval.start) else {
                return nil
            }
            let isCurrentMonth = calendar.isDate(date, equalTo: monthInterval.start, toGranularity: .month)
            return CalendarMonthDay(date: date, isCurrentMonth: isCurrentMonth)
        }
    }

    @ViewBuilder
    private func dayCell(_ day: CalendarMonthDay) -> some View {
        let isToday = calendar.isDateInToday(day.date)

        Text(dayLabel(for: day.date))
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(isToday ? Color.white : day.isCurrentMonth ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isToday ? Color.accentColor : Color.secondary.opacity(day.isCurrentMonth ? 0.08 : 0.04))
            )
    }

    private func dayLabel(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }
}

private struct CalendarMonthDay {
    let date: Date
    let isCurrentMonth: Bool
}
