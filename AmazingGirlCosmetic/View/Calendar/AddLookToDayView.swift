
import SwiftUI

struct AddLookToDayView: View {
    @EnvironmentObject private var store: BeautyStore
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let onPicked: () -> Void

    var body: some View {
        ZStack {
            AppColor.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                AppNavBar(title: "Add look", onBack: { dismiss() }, onAdd: nil)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        ForEach(store.looks, id: \.id) { look in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(look.title)
                                    .font(AppFont.make(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)

                                LookRowCard(
                                    cosmetics: store.cosmeticsForLook(look, limit: 5),
                                    note: look.note,
                                    onEdit: {},
                                    onDelete: {}
                                )
                                .padding(.horizontal, 20)
                                .highPriorityGesture(
                                    TapGesture().onEnded {
                                        store.addLookToDay(
                                            dayKey: store.dayKey(for: date),
                                            lookID: look.id
                                        )
                                        dismiss()
                                        onPicked()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
    }
}

#Preview {
    AddLookToDayView(date: Date(), onPicked: {})
        .environmentObject(BeautyStore())
        .navigationBarBackButtonHidden()
}
