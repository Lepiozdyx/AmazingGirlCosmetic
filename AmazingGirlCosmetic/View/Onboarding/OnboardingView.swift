import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Binding var seenOnboarding: Bool
    @State private var currentPage: Int = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "onboarding1",
            title: "Amazing Girl Cosmetic",
            subtitle: "Your personal beauty assistant is getting ready…"
        ),
        OnboardingPage(
            image: "onboarding2",
            title: "Discover Your Beauty",
            subtitle: "Loading your makeup collection and looks"
        ),
        OnboardingPage(
            image: "onboarding3",
            title: "Get Ready to Glow",
            subtitle: "Analyzing your routine…"
        )
    ]
    
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppColor.background
                    .ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 0) {
                    Image(pages[currentPage].image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: geo.size.height * 1.5 / 3)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .ignoresSafeArea(edges: .top)
                    Spacer()
                    bottomContent
                }
            }
        }
    }
    
    private var bottomContent: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                Text(pages[currentPage].title)
                    .font(AppFont.make(size: 32, weight: .bold))
                    .foregroundColor(AppColor.blue)
                
                Text(pages[currentPage].subtitle)
                    .font(AppFont.make(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(4)
            }
            .multilineTextAlignment(.center)
                        
            button
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    private var button: some View {
        Button {
            if isLastPage {
                seenOnboarding = true
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentPage += 1
                }
            }
        } label: {
            Text(isLastPage ? "Get started" : "Next")
                .font(AppFont.make(size: 32, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 58)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColor.orange)
                )
        }
        .buttonStyle(.plain)
        .frame(width: UIScreen.main.bounds.width / 2)
    }
}

#Preview {
    OnboardingView(seenOnboarding: .constant(false))
}
