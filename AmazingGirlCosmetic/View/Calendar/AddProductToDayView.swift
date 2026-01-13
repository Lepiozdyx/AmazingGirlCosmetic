import SwiftUI

struct AddProductToDayView: View {
    @EnvironmentObject private var store: BeautyStore
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let onPicked: () -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 22),
        GridItem(.flexible(), spacing: 22)
    ]

    private let horizontalPadding: CGFloat = 16
    private let topPadding: CGFloat = 18

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Add product", onBack: { dismiss() }, onAdd: nil)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(store.cosmetics) { item in
                            CosmeticCard(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.addCosmeticToDay(
                                        dayKey: store.dayKey(for: date),
                                        cosmeticID: item.id
                                    )
                                    dismiss()
                                    onPicked()
                                }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topPadding)
                }
            }
        }
    }
}

#Preview {
    AddProductToDayView(date: Date(), onPicked: {})
        .environmentObject(BeautyStore())
        .navigationBarBackButtonHidden()
}
