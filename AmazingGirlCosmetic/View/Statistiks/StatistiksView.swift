import SwiftUI

enum StatsRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

struct StatisticsView: View {
    @EnvironmentObject private var store: BeautyStore
    @State private var range: StatsRange = .week

    private let floatingTabBarHeight: CGFloat = 70
    private let floatingTabBarOuterBottomPadding: CGFloat = 6
    private let floatingTabBarExtraSafeGap: CGFloat = 22

    private var scrollBottomPadding: CGFloat {
        floatingTabBarHeight + floatingTabBarOuterBottomPadding + floatingTabBarExtraSafeGap
    }

    private var hasAnyCosmeticsUsageEver: Bool {
        store.usage.contains { !$0.cosmeticIDs.isEmpty }
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Statistics", onBack: nil, onAdd: nil)

                if !hasAnyCosmeticsUsageEver {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            StatsRangePicker(selected: $range)

                            let model = StatsModel.build(store: store, range: range)

                            if model.totalCount == 0 {
                                emptyStateInside
                            } else {
                                chartBlock(model: model)
                                insightBlock(model: model)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .padding(.bottom, scrollBottomPadding)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Start tracking usage to see your statistics!")
                .font(AppFont.make(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
            Spacer()
        }
    }

    private var emptyStateInside: some View {
        VStack {
            Spacer(minLength: 10)
            Text("Start tracking usage to see your statistics!")
                .font(AppFont.make(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 36)
    }

    private func chartBlock(model: StatsModel) -> some View {
        HStack(alignment: .top, spacing: 18) {
            DonutChartView(
                segments: model.segments,
                centerTopText: model.periodTopLine,
                centerBottomText: model.periodBottomLine
            )
            .frame(width: 210, height: 210)

            VStack(alignment: .leading, spacing: 12) {
                Text("Categories:")
                    .font(AppFont.make(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.legendRows) { row in
                        Text("\(row.title) - \(row.percent)%")
                            .font(AppFont.make(size: 12, weight: .semibold))
                            .foregroundStyle(row.color)
                    }
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func insightBlock(model: StatsModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insight")
                .font(AppFont.make(size: 24, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                if let top = model.topCosmeticInsight {
                    InsightCard(text: top)
                }
                if let gap = model.gapInsight {
                    InsightCard(text: gap)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
}

private struct StatsRangePicker: View {
    @Binding var selected: StatsRange
    private let height: CGFloat = 30

    var body: some View {
        HStack(spacing: 0) {
            button(.week)
            divider
            button(.month)
        }
        .frame(width: 260, height: height)
        .overlay(
            Rectangle()
                .stroke(AppColor.orange, lineWidth: 2)
        )
        .padding(.top, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColor.orange)
            .frame(width: 2)
    }

    private func button(_ value: StatsRange) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.16)) {
                selected = value
            }
        } label: {
            ZStack {
                if selected == value {
                    Rectangle().fill(AppColor.blue)
                } else {
                    Rectangle().fill(Color.clear)
                }

                Text(value.rawValue)
                    .font(AppFont.make(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DonutChartView: View {
    struct Segment: Identifiable {
        let id = UUID()
        let color: Color
        let fraction: Double
    }

    let segments: [Segment]
    let centerTopText: String
    let centerBottomText: String

    private let outerLineWidth: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .stroke(AppColor.blue, lineWidth: 2)

                Canvas { context, _ in
                    var startAngle = -Double.pi / 2

                    for seg in segments {
                        let endAngle = startAngle + (Double.pi * 2 * max(0, seg.fraction))

                        var path = Path()
                        path.addArc(
                            center: center,
                            radius: radius - outerLineWidth / 2,
                            startAngle: Angle(radians: startAngle),
                            endAngle: Angle(radians: endAngle),
                            clockwise: false
                        )

                        context.stroke(
                            path,
                            with: .color(seg.color),
                            style: StrokeStyle(lineWidth: outerLineWidth, lineCap: .butt, lineJoin: .miter)
                        )

                        startAngle = endAngle
                    }
                }

                Circle()
                    .fill(AppColor.backgroundGray)
                    .frame(
                        width: max(0, size - (outerLineWidth * 2)),
                        height: max(0, size - (outerLineWidth * 2))
                    )

                VStack(spacing: 6) {
                    Text(centerTopText)
                        .font(AppFont.make(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(centerBottomText)
                        .font(AppFont.make(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct InsightCard: View {
    let text: String
    private let corner: CGFloat = 18

    var body: some View {
        HStack {
            Text(text)
                .font(AppFont.make(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .background(AppColor.backgroundGray)
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(AppColor.orange, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

private struct StatsModel {
    struct LegendRow: Identifiable {
        let id = UUID()
        let title: String
        let percent: Int
        let color: Color
    }

    let totalCount: Int
    let periodTopLine: String
    let periodBottomLine: String
    let segments: [DonutChartView.Segment]
    let legendRows: [LegendRow]
    let topCosmeticInsight: String?
    let gapInsight: String?

    static func build(store: BeautyStore, range: StatsRange) -> StatsModel {
        let cal = Calendar.current
        let today = Date()

        let startDate: Date = {
            let start = cal.startOfDay(for: today)
            switch range {
            case .week:
                return cal.date(byAdding: .day, value: -6, to: start) ?? start
            case .month:
                return cal.date(byAdding: .day, value: -29, to: start) ?? start
            }
        }()

        let endDate = cal.startOfDay(for: today)

        let periodTop = formatDate(startDate)
        let periodBottom = formatDate(endDate)

        let entries = store.usageInRange(startDate: startDate, endDate: endDate)

        var catCount: [CosmeticCategory: Int] = [:]
        var cosmeticCount: [UUID: Int] = [:]
        var lastUsedCategoryDate: [CosmeticCategory: Date] = [:]

        for entry in entries {
            let date = parseDayKey(entry.dayKey) ?? endDate
            for id in entry.cosmeticIDs {
                cosmeticCount[id, default: 0] += 1

                if let item = store.cosmetic(by: id) {
                    catCount[item.category, default: 0] += 1

                    if let prev = lastUsedCategoryDate[item.category] {
                        if date > prev { lastUsedCategoryDate[item.category] = date }
                    } else {
                        lastUsedCategoryDate[item.category] = date
                    }
                }
            }
        }

        let total = catCount.values.reduce(0, +)

        let legend: [LegendRow] = CosmeticCategory.allCases.compactMap { cat in
            guard let count = catCount[cat], count > 0, total > 0 else { return nil }
            let pct = Int(round(Double(count) * 100.0 / Double(total)))
            return LegendRow(title: cat.rawValue, percent: pct, color: cat.color)
        }
        .sorted { $0.percent > $1.percent }

        let segments: [DonutChartView.Segment] = legend.map { row in
            DonutChartView.Segment(color: row.color, fraction: Double(row.percent) / 100.0)
        }

        let topInsight: String? = {
            guard total > 0 else { return nil }
            guard let (topID, topCount) = cosmeticCount.max(by: { $0.value < $1.value }) else { return nil }
            guard let topItem = store.cosmetic(by: topID) else { return nil }

            let allUses = max(1, entries.reduce(0) { $0 + $1.cosmeticIDs.count })
            let pct = Int(round(Double(topCount) * 100.0 / Double(allUses)))

            return "\(topItem.name) \(topItem.category.rawValue.lowercased()) is your favorite — \(pct)% of all uses!"
        }()

        let gapInsight: String? = {
            guard store.usage.contains(where: { !$0.cosmeticIDs.isEmpty }) else { return nil }

            var worst: (CosmeticCategory, Int)? = nil
            for cat in CosmeticCategory.allCases {
                let last = lastUsedCategoryDate[cat] ?? store.lastUsageDate(for: cat)
                guard let last else { continue }
                let days = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: today)).day ?? 0)

                if let w = worst {
                    if days > w.1 { worst = (cat, days) }
                } else {
                    worst = (cat, days)
                }
            }

            guard let (cat, days) = worst, days >= 7 else { return nil }

            if let lookTitle = store.suggestedLookTitle(forMissingCategory: cat) {
                return "You haven't used \(cat.rawValue.lowercased()) for \(days) days — try the “\(lookTitle)” look!"
            } else {
                return "You haven't used \(cat.rawValue.lowercased()) for \(days) days — try a new look!"
            }
        }()

        return StatsModel(
            totalCount: total,
            periodTopLine: periodTop,
            periodBottomLine: periodBottom,
            segments: segments,
            legendRows: legend,
            topCosmeticInsight: topInsight,
            gapInsight: gapInsight
        )
    }

    private static func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }

    private static func parseDayKey(_ key: String) -> Date? {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: key)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(BeautyStore())
}
