import SwiftUI

struct RootView: View {
    @StateObject private var store = BeautyStore()
    @AppStorage("SeenOnboarding") private var seenOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if seenOnboarding {
                    AppTabContainer()
                } else {
                    OnboardingView(seenOnboarding: $seenOnboarding)
                }
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
