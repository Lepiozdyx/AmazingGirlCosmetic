import SwiftUI
enum AppTab: CaseIterable, Identifiable {
    case cosmetics
    case looks
    case calendar
    case statistics

    var id: String { title }

    var title: String {
        switch self {
        case .cosmetics: return "Cosmetics"
        case .looks: return "Looks"
        case .calendar: return "Calendar"
        case .statistics: return "Statistics"
        }
    }

    var iconAssetName: String {
        switch self {
        case .cosmetics: return "tab_cosmetics"
        case .looks: return "tab_looks"
        case .calendar: return "tab_calendar"
        case .statistics: return "tab_statistics"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    private let barColor = AppColor.blue
    private let activeColor = AppColor.orange
    private let inactiveColor = Color.white

    private let barHeight: CGFloat = 70
    private let horizontalPadding: CGFloat = 33
    private let bottomPadding: CGFloat = 6

    var body: some View {
        HStack {
            ForEach(Array(AppTab.allCases.enumerated()), id: \.element) { index, tab in
                tabButton(for: tab)

                if index < AppTab.allCases.count - 1 {
                    Spacer(minLength: 20)
                }
            }
        }
        .frame(height: barHeight)
        .padding(.horizontal, horizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(barColor)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, bottomPadding)
    }

    private func tabButton(for tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 10) {
                Image(tab.iconAssetName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isSelected(tab) ? activeColor : inactiveColor)

                Text(tab.title)
                    .font(AppFont.make(size: 12, weight: .medium))
                    .foregroundColor(isSelected(tab) ? activeColor : inactiveColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ tab: AppTab) -> Bool {
        selectedTab == tab
    }
}

#Preview {
    AppTabContainer()
}
