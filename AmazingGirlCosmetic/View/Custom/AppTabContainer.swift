import SwiftUI

struct AppTabContainer: View {
    @EnvironmentObject private var store: BeautyStore
    @State private var selectedTab: AppTab = .cosmetics
    var body: some View {
        ZStack {
            currentScreen
                .environmentObject(store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background.ignoresSafeArea())

            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .cosmetics:
            CosmeticsView()
        case .looks:
            LooksView()
        case .calendar:
            CalendarView()
        case .statistics:
            StatisticsView()
        }
    }
}

#Preview {
    AppTabContainer()
        .environmentObject(BeautyStore())
}
