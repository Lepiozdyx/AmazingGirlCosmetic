import SwiftUI

struct LooksView: View {
    @EnvironmentObject private var store: BeautyStore

    @State private var showAdd = false
    @State private var showEdit = false
    @State private var selectedLook: Look? = nil

    private let floatingTabBarHeight: CGFloat = 70
    private let floatingTabBarOuterBottomPadding: CGFloat = 6
    private let floatingTabBarExtraSafeGap: CGFloat = 22

    private var scrollBottomPadding: CGFloat {
        floatingTabBarHeight + floatingTabBarOuterBottomPadding + floatingTabBarExtraSafeGap
    }

    var body: some View {
        ZStack {
            AppColor.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                AppNavBar(title: "Looks", onBack: nil) {
                    showAdd = true
                }

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
                                    onEdit: {
                                        selectedLook = look
                                        showEdit = true
                                    },
                                    onDelete: {
                                        store.deleteLook(id: look.id)
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, scrollBottomPadding)
                }
            }
        }
        .navigationDestination(isPresented: $showAdd) {
            AddEditLookView(mode: .add)
                .environmentObject(store)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $showEdit) {
            if let selectedLook {
                AddEditLookView(mode: .edit(selectedLook))
                    .environmentObject(store)
                    .navigationBarBackButtonHidden()
            } else {
                EmptyView()
            }
        }
        .onChange(of: showEdit) { isShown in
            if !isShown { selectedLook = nil }
        }
    }
}

struct LookRowCard: View {
    let cosmetics: [CosmeticItem]
    let note: String?
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let corner: CGFloat = 16
    private let height: CGFloat = 120

    private let actionSize: CGFloat = 64
    private let actionSpacing: CGFloat = 14
    private var actionsWidth: CGFloat { actionSize * 2 + actionSpacing + 8 }

    @State private var baseOffsetX: CGFloat = 0
    @State private var dragOffsetX: CGFloat = 0
    @State private var directionLocked: Bool = false
    @State private var isHorizontal: Bool = false

    private var effectiveOffset: CGFloat {
        let x = baseOffsetX + (isHorizontal ? dragOffsetX : 0)
        return max(-actionsWidth, min(0, x))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: actionSpacing) {
                CircleActionButton(systemName: "pencil", fill: AppColor.orange) {
                    close()
                    onEdit()
                }
                CircleActionButton(systemName: "trash", fill: AppColor.red) {
                    close()
                    onDelete()
                }
            }
            .frame(width: actionsWidth, height: height, alignment: .trailing)

            cardContent
                .offset(x: effectiveOffset)
                .highPriorityGesture(dragGesture)
                .onTapGesture {
                    if baseOffsetX != 0 { close() }
                }
        }
        .frame(height: height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                if !directionLocked {
                    let ax = abs(value.translation.width)
                    let ay = abs(value.translation.height)
                    if ax > 8 || ay > 8 {
                        directionLocked = true
                        isHorizontal = ax > ay
                    }
                }

                if isHorizontal {
                    dragOffsetX = value.translation.width
                }
            }
            .onEnded { value in
                defer {
                    dragOffsetX = 0
                    directionLocked = false
                    isHorizontal = false
                }

                guard directionLocked, isHorizontal else { return }

                let predicted = baseOffsetX + value.predictedEndTranslation.width
                let shouldOpen = predicted < -actionsWidth * 0.35

                withAnimation(.spring(response: 0.26, dampingFraction: 0.92)) {
                    baseOffsetX = shouldOpen ? -actionsWidth : 0
                }
            }
    }

    private var cardContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppColor.backgroundGray) // 222222

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ForEach(Array(cosmetics.prefix(3)), id: \.id) { item in
                        LookPreviewMiniCard(item: item)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let noteText = note?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !noteText.isEmpty {
                    Text("“\(noteText)”")
                        .font(AppFont.make(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                } else {
                    Text(" ")
                        .font(AppFont.make(size: 18, weight: .semibold))
                        .foregroundStyle(.clear)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(AppColor.orange, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private func close() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.95)) {
            baseOffsetX = 0
        }
    }
}


struct LookPreviewMiniCard: View {
    let item: CosmeticItem

    private let size: CGFloat = 64
    private let corner: CGFloat = 14

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.white)

                if let data = item.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(AppColor.orange, lineWidth: 2)
            )

            Text(item.name)
                .font(AppFont.make(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: size + 10)
        }
    }
}

private struct CircleActionButton: View {
    let systemName: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 64, height: 64)

                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LooksView()
        .environmentObject(BeautyStore())
}
