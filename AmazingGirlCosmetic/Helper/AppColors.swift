//
//  AppColors.swift
//  AmazingGirlCosmetic
//
//  Created by Алексей Авер on 17.12.2025.
//

import Foundation

import SwiftUI

enum AppColor {

    static let background = Color(hex: "00050D")

    static let backgroundGray = Color(hex: "222222")

    static let blue = Color(hex: "197FD2")

    static let orange = Color(hex: "F99A34")

    static let red = Color(hex: "D21919")

    static let violet = Color(hex: "8E19D2")

    static let pink = Color(hex: "D219B0")

    static let green = Color(hex: "19D22F")

    static let mint = Color(hex: "19C6D2")
}

extension Color {

    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 0; g = 0; b = 0
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: alpha
        )
    }
}
