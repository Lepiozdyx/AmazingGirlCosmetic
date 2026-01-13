import SwiftUI
import UIKit

enum AppFont {

    enum Weight {
        case regular
        case medium
        case semibold
        case bold

        fileprivate var uiWeight: UIFont.Weight {
            switch self {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
            }
        }
    }

    enum Token {
        case largeTitle
        case title
        case section
        case body
        case secondary
        case caption
        case tiny

        fileprivate var size: CGFloat {
            switch self {
            case .largeTitle: return 32
            case .title:      return 24
            case .section:    return 18
            case .body:       return 16
            case .secondary:  return 14
            case .caption:    return 12
            case .tiny:       return 10
            }
        }

        fileprivate var defaultWeight: Weight {
            switch self {
            case .largeTitle: return .bold
            case .title:      return .bold
            case .section:    return .semibold
            case .body:       return .regular
            case .secondary:  return .regular
            case .caption:    return .medium
            case .tiny:       return .regular
            }
        }
    }

    static func make(
        size: CGFloat,
        weight: Weight
    ) -> Font {
        let uiFont = UIFont.systemFont(
            ofSize: size,
            weight: weight.uiWeight
        )

       
        return Font(uiFont)
    }

    static func font(
        _ token: Token,
        weight: Weight? = nil
    ) -> Font {
        make(
            size: token.size,
            weight: weight ?? token.defaultWeight
        )
    }
}


//Text("Custom label")
//    .font(AppFont.make(size: 15, weight: .semibold))
