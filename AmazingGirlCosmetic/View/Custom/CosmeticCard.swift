import SwiftUI

struct CosmeticCard: View {
    let item: CosmeticItem

    private let imageCorner: CGFloat = 16
    private let strokeWidth: CGFloat = 2

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: imageCorner, style: .continuous)
                            .fill(Color.white)

                        if let data = item.photoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)

                    StatusNotchBadge(
                        text: item.status == .inUse ? "In use" : "In reserve",
                        fill: item.status == .inUse ? AppColor.orange : AppColor.blue
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: imageCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: imageCorner, style: .continuous)
                        .stroke(AppColor.orange, lineWidth: strokeWidth)
                )
            }

            Text(item.name)
                .font(AppFont.make(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(item.category.rawValue)
                .font(AppFont.make(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.blue)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

private struct StatusNotchBadge: View {
    let text: String
    let fill: Color

    private let height: CGFloat = 26
    private let horizontalPadding: CGFloat = 12
    private let bottomLeftCorner: CGFloat = 6

    var body: some View {
        Text(text)
            .font(AppFont.make(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(fill)
            .clipShape(CustomCornerRadius(radius: bottomLeftCorner, corners: [.bottomLeft]))
    }
}

private struct CustomCornerRadius: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
