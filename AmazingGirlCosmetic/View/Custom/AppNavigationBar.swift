import SwiftUI

struct AppNavBar: View {
    let title: String
    let onBack: (() -> Void)?
    let onAdd: (() -> Void)?
    
    var body: some View {
        ZStack {
            AppColor.blue

            HStack {
                ZStack {
                    if let onBack = onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 9, height: 19)
                                .foregroundColor(.white)
                        }
                    }
                }

                Text(title)
                    .font(AppFont.make(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                ZStack {
                    if let onAdd = onAdd {
                        Button(action: onAdd) {
                            Image(.plusButton)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .frame(height: 44)
        .background(AppColor.blue)
    }
}
