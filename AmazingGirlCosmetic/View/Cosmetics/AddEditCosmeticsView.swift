import SwiftUI
import PhotosUI
import UIKit

enum CosmeticEditorMode: Equatable {
    case add
    case edit(CosmeticItem)

    var navTitle: String {
        switch self {
        case .add: return "Add cosmetic"
        case .edit: return "Edit cosmetic"
        }
    }
}

struct AddEditCosmeticsView: View {
    @EnvironmentObject private var store: BeautyStore
    @Environment(\.dismiss) private var dismiss

    let mode: CosmeticEditorMode

    @State private var name: String = ""
    @State private var category: CosmeticCategory? = nil
    @State private var isCategorySheetPresented: Bool = false
    @State private var type: CosmeticType? = nil
    @State private var status: CosmeticStatus = .inUse

    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    @State private var editingID: UUID? = nil

    private let contentHorizontalPadding: CGFloat = 20
    private let fieldHeight: CGFloat = 52
    private let photoBoxSize: CGFloat = 120

    private var isSaveEnabled: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && category != nil
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    @State private var isPhotoSourceDialogPresented: Bool = false
    @State private var isLegacyImagePickerPresented: Bool = false
    @State private var legacyPickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        ZStack {
            AppColor.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                AppNavBar(
                    title: mode.navTitle,
                    onBack: { dismiss() },
                    onAdd: nil
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        photoBlock
                            .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 10) {
                            RequiredTitle(text: "Name:")
                            AppTextField(text: $name, height: fieldHeight)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            RequiredTitle(text: "Category:")
                            categoryDropdown
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            OptionalTitle(text: "Type:")
                            typeChipsRow
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            RequiredTitle(text: "Status:")
                            statusChipsRow
                        }

                        bottomButtons
                            .padding(.top, 16)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, contentHorizontalPadding)
                    .padding(.top, 14)
                }
            }
        }
        .onAppear { setupInitialState() }

        .onChange(of: photoPickerItem) { newItem in
            guard let newItem else { return }
            Task { await loadPhoto(from: newItem) }
        }

        .sheet(isPresented: $isCategorySheetPresented) {
            CategoryBottomSheet(
                selected: $category,
                onSelect: { isCategorySheetPresented = false }
            )
            .presentationDetents([.medium])
        }

        .confirmationDialog(
            "Add a photo",
            isPresented: $isPhotoSourceDialogPresented,
            titleVisibility: .visible
        ) {
            Button("Take Photo") {
                openLegacyPicker(.camera)
            }
            Button("Choose from Library") {
                openLegacyPicker(.photoLibrary)
            }
            if photoData != nil {
                Button("Remove Photo", role: .destructive) {
                    photoPickerItem = nil
                    photoData = nil
                }
            }
            Button("Cancel", role: .cancel) { }
        }

        .fullScreenCover(isPresented: $isLegacyImagePickerPresented) {
            LegacyImagePicker(
                sourceType: legacyPickerSource,
                onImagePicked: { image in
                    let cropped = image.centerCroppedToSquare()
                    let resized = cropped.resized(to: CGSize(width: photoBoxSize * 2, height: photoBoxSize * 2))
                    self.photoData = resized.jpegData(compressionQuality: 0.85)
                },
                onCancel: { }
            )
            .ignoresSafeArea()
        }
    }

    private var photoBlock: some View {
        VStack(spacing: 10) {
            Button {
                isPhotoSourceDialogPresented = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.orange, lineWidth: 1.5)
                        .frame(width: photoBoxSize, height: photoBoxSize)

                    if let photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: photoBoxSize, height: photoBoxSize)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Add a photo")
                                .font(AppFont.make(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryDropdown: some View {
        Button {
            isCategorySheetPresented = true
        } label: {
            HStack {
                Text(category?.rawValue ?? "")
                    .font(AppFont.make(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(category == nil ? 0.0 : 1.0))

                if category == nil {
                    Text("Select category")
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

    private var typeChipsRow: some View {
        HStack(spacing: 12) {
            TypeChip(title: "Matte", isSelected: type == .matte) { toggleType(.matte) }
            TypeChip(title: "Radiant", isSelected: type == .radiant) { toggleType(.radiant) }
            TypeChip(title: "Liquid", isSelected: type == .liquid) { toggleType(.liquid) }
            TypeChip(title: "Powder", isSelected: type == .powder) { toggleType(.powder) }
        }
    }

    private func toggleType(_ newValue: CosmeticType) {
        type = (type == newValue) ? nil : newValue
    }

    private var statusChipsRow: some View {
        HStack(spacing: 14) {
            StatusChip(
                title: "In use",
                isSelected: status == .inUse,
                accentColor: AppColor.orange
            ) {
                status = .inUse
            }

            StatusChip(
                title: "In reserve",
                isSelected: status == .inReserve,
                accentColor: AppColor.blue
            ) {
                status = .inReserve
            }
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 16) {
            if isEditMode {
                Button {
                    deleteItem()
                } label: {
                    Text("Delete")
                        .font(AppFont.make(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 56)
                        .background(AppColor.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                save()
            } label: {
                Text("Save")
                    .font(AppFont.make(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: isEditMode ? 160 : 220, height: 56)
                    .background(isSaveEnabled ? AppColor.orange : AppColor.backgroundGray.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isSaveEnabled)
            .opacity(isSaveEnabled ? 1.0 : 0.55)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func openLegacyPicker(_ source: UIImagePickerController.SourceType) {
        if source == .camera {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        }
        legacyPickerSource = source
        isLegacyImagePickerPresented = true
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let category else { return }

        switch mode {
        case .add:
            store.addCosmetic(
                name: trimmedName,
                category: category,
                type: type,
                status: status,
                photoData: photoData
            )
        case .edit(let original):
            let updated = CosmeticItem(
                id: original.id,
                name: trimmedName,
                category: category,
                type: type,
                status: status,
                photoData: photoData
            )
            store.updateCosmetic(updated)
        }

        dismiss()
    }

    private func deleteItem() {
        guard case .edit(let original) = mode else { return }
        store.deleteCosmetic(id: original.id)
        dismiss()
    }

    private func setupInitialState() {
        switch mode {
        case .add:
            editingID = nil
            name = ""
            category = nil
            type = nil
            status = .inUse
            photoData = nil
            photoPickerItem = nil
        case .edit(let item):
            editingID = item.id
            name = item.name
            category = item.category
            type = item.type
            status = item.status
            photoData = item.photoData
            photoPickerItem = nil
        }
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let cropped = image.centerCroppedToSquare()
                let resized = cropped.resized(to: CGSize(width: photoBoxSize * 2, height: photoBoxSize * 2))
                let outData = resized.jpegData(compressionQuality: 0.85)
                await MainActor.run { self.photoData = outData }
            }
        } catch {
            print("❌ Failed to load photo:", error)
        }
    }
}

private struct LegacyImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImagePicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            picker.dismiss(animated: true)

            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
        }
    }
}


private extension UIImage {
    func centerCroppedToSquare() -> UIImage {
        let w = size.width
        let h = size.height
        let side = min(w, h)
        let x = (w - side) / 2
        let y = (h - side) / 2

        guard let cg = cgImage else { return self }

        let scale = self.scale
        let rect = CGRect(x: x * scale, y: y * scale, width: side * scale, height: side * scale)

        guard let cropped = cg.cropping(to: rect) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }

    func resized(to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}


struct CategoryBottomSheet: View {
    @Binding var selected: CosmeticCategory?
    let onSelect: () -> Void
    var body: some View {
        ZStack {
            AppColor.backgroundGray
                .ignoresSafeArea()
            
                VStack(spacing: 10) {
                    ForEach(CosmeticCategory.allCases) { category in
                        Button {
                            selected = category
                            onSelect()
                        } label: {
                            Text(category.rawValue)
                                .font(AppFont.make(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct RequiredTitle: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(AppFont.make(size: 26, weight: .bold))
                .foregroundStyle(.white)
            
            Text("*")
                .font(AppFont.make(size: 26, weight: .bold))
                .foregroundStyle(AppColor.orange)
        }
    }
}

private struct OptionalTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(AppFont.make(size: 26, weight: .bold))
            .foregroundStyle(.white)
    }
}

struct AppTextField: View {
    @Binding var text: String
    let height: CGFloat
    
    var body: some View {
        TextField("", text: $text)
            .font(AppFont.make(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(AppColor.backgroundGray)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled(true)
    }
}

private struct TypeChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFont.make(size: 15, weight: .semibold))
                .minimumScaleFactor(0.5)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? AppColor.orange : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(AppColor.orange, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct StatusChip: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(AppFont.make(size: 16, weight: .bold))
                .foregroundStyle(isSelected ? .white : .white)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? accentColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(accentColor, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddEditCosmeticsView(mode: .add)
        .environmentObject(BeautyStore())
}
