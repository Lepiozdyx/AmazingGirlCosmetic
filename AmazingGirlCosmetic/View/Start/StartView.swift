import SwiftUI

struct StartView: View {
    @State private var progress: CGFloat = 0.5
    var body: some View {
        ZStack {
            Image(.startBack)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                Spacer()
                Image(.startLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.8)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Spacer()
                Text("LOADING...")
                    .font(AppFont.make(size: 20, weight: .bold))
                    .foregroundStyle(AppColor.orange)
                
                GeometryReader { geo in
                    ZStack {
                        Capsule()
                            .fill(.white.opacity(0.1))
                        
                        HStack(spacing: 0) {
                            Capsule()
                                .fill(AppColor.orange)
                                .frame(width: geo.size.width * progress)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(height: 24)
                .padding(20)

            }
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                progress = 1
            }
        }
    }
}

#Preview {
    StartView()
}
