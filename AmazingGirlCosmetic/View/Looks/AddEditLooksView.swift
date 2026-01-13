//
//  AddEditLookView.swift
//  AmazingGirlCosmetic
//
//  Created by Алексей Авер on 19.12.2025.
//

import SwiftUI

enum LookEditorMode: Equatable {
    case add
    case edit(Look)

    var navTitle: String {
        switch self {
        case .add: return "Add new look"
        case .edit: return "Edit look"
        }
    }
}

struct AddEditLookView: View {
    @EnvironmentObject private var store: BeautyStore
    @Environment(\.dismiss) private var dismiss

    let mode: LookEditorMode

    @State private var name: String = ""
    @State private var note: String = ""

    @State private var selectedCategory: CosmeticCategory? = nil
    @State private var isCategorySheetPresented: Bool = false

    @State private var selectedProductIDs: [UUID] = []

    @State private var availableWidth: CGFloat = 0

    private let contentHorizontalPadding: CGFloat = 20
    private let fieldHeight: CGFloat = 52
    private let cardSize: CGFloat = 86
    private let cardCorner: CGFloat = 14

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var inUseCosmetics: [CosmeticItem] {
        store.inUseCosmetics()
    }

    private var filteredCosmetics: [CosmeticItem] {
        guard let selectedCategory else { return inUseCosmetics }
        return inUseCosmetics.filter { $0.category == selectedCategory }
    }

    private var isSaveEnabled: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !selectedProductIDs.isEmpty
    }

    var body: some View {
        ZStack {
            AppColor.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                AppNavBar(title: mode.navTitle, onBack: { dismiss() }, onAdd: nil)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {

                        VStack(alignment: .leading, spacing: 10) {
                            RequiredTitle(text: "Name:")
                            AppTextField(text: $name, height: fieldHeight)
                        }
                        .padding(.horizontal, contentHorizontalPadding)

                        VStack(alignment: .leading, spacing: 10) {
                            OptionalTitle(text: "Note:")
                            AppTextField(text: $note, height: fieldHeight)
                        }
                        .padding(.horizontal, contentHorizontalPadding)

                        VStack(alignment: .leading, spacing: 10) {
                            OptionalTitle(text: "Category:")
                            categoryDropdown
                        }
                        .padding(.horizontal, contentHorizontalPadding)

                        cosmeticsRow
                            .frame(width: max(availableWidth, 0))
                            .clipped()

                        bottomButtons
                            .padding(.top, 16)
                            .padding(.bottom, 30)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, contentHorizontalPadding)

                    }
                    .padding(.top, 14)
                    .background(WidthReader { w in
                        if availableWidth != w {
                            availableWidth = w
                        }
                    })
                }
            }
        }
        .onAppear { setupInitialState() }
        .sheet(isPresented: $isCategorySheetPresented) {
            CategoryBottomSheet(
                selected: $selectedCategory,
                onSelect: { isCategorySheetPresented = false }
            )
            .presentationDetents([.medium])
        }
    }

    private var categoryDropdown: some View {
        Button {
            isCategorySheetPresented = true
        } label: {
            HStack {
                Text(selectedCategory?.rawValue ?? "")
                    .font(AppFont.make(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(selectedCategory == nil ? 0.0 : 1.0))

                if selectedCategory == nil {
                    Text("All categories")
                        .font(AppFont.make(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: fieldHeight)
            .background(AppColor.backgroundGray)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // HIG: в начале есть inset, при скролле он визуально исчезает (элементы уходят под маску)
    // ВАЖНО: ширина ряда жёстко равна ширине экрана (availableWidth), поэтому ничего не "распирает".
    private var cosmeticsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(filteredCosmetics) { item in
                    LookCosmeticMiniCard(
                        item: item,
                        size: cardSize,
                        corner: cardCorner,
                        isSelected: selectedProductIDs.contains(item.id),
                        onTap: { toggleProduct(item.id) },
                        onRemove: { removeProduct(item.id) }
                    )
                }
            }
            .padding(.leading, contentHorizontalPadding)
            .padding(.trailing, contentHorizontalPadding)
        }
        .frame(height: cardSize + 44)
        .overlay(alignment: .leading) {
            AppColor.background
                .frame(width: contentHorizontalPadding)
                .allowsHitTesting(false)
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            if isEditMode {
                Button {
                    deleteLook()
                } label: {
                    Text("Delete")
                        .font(AppFont.make(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 56)
                        .background(AppColor.red)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                saveLook()
            } label: {
                Text("Save")
                    .font(AppFont.make(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: isEditMode ? 160 : 220, height: 56)
                    .background(isSaveEnabled ? AppColor.orange : AppColor.backgroundGray.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isSaveEnabled)
            .opacity(isSaveEnabled ? 1.0 : 0.55)
        }
    }

    private func toggleProduct(_ id: UUID) {
        if let idx = selectedProductIDs.firstIndex(of: id) {
            selectedProductIDs.remove(at: idx)
        } else {
            selectedProductIDs.append(id)
        }
    }

    private func removeProduct(_ id: UUID) {
        selectedProductIDs.removeAll { $0 == id }
    }

    private func setupInitialState() {
        switch mode {
        case .add:
            name = ""
            note = ""
            selectedCategory = nil
            selectedProductIDs = []

        case .edit(let look):
            name = look.title
            note = look.note ?? ""
            selectedCategory = nil
            selectedProductIDs = look.cosmeticIDs
        }
    }

    private func saveLook() {
        let trimmedTitle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard !selectedProductIDs.isEmpty else { return }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote: String? = trimmedNote.isEmpty ? nil : trimmedNote

        switch mode {
        case .add:
            store.addLook(title: trimmedTitle, note: finalNote, cosmeticIDs: selectedProductIDs)

        case .edit(let original):
            let updated = Look(id: original.id, title: trimmedTitle, note: finalNote, cosmeticIDs: selectedProductIDs)
            store.updateLook(updated)
        }

        dismiss()
    }

    private func deleteLook() {
        guard case .edit(let original) = mode else { return }
        store.deleteLook(id: original.id)
        dismiss()
    }
}

// MARK: - Mini Card (в редакторе лука)

private struct LookCosmeticMiniCard: View {
    let item: CosmeticItem
    let size: CGFloat
    let corner: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
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
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Button(action: onRemove) {
                            ZStack {
                                Circle()
                                    .fill(AppColor.red)
                                    .frame(width: 18, height: 18)

                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                    }
                }
            }
            .onTapGesture { onTap() }

            Text(item.name)
                .font(AppFont.make(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: size)

            Text(item.category.rawValue)
                .font(AppFont.make(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.blue)
                .lineLimit(1)
                .frame(width: size)
        }
    }
}

private struct RequiredTitle: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("*")
                .font(AppFont.make(size: 22, weight: .bold))
                .foregroundStyle(AppColor.orange)
        }
    }
}

private struct OptionalTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.make(size: 22, weight: .bold))
            .foregroundStyle(.white)
    }
}


private struct WidthReader: View {
    let onChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: WidthPreferenceKey.self, value: geo.size.width)
        }
        .onPreferenceChange(WidthPreferenceKey.self) { w in
            onChange(w)
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    AddEditLookView(mode: .add)
        .environmentObject(BeautyStore())
}
