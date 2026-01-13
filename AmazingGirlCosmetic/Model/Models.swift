//
//  Models.swift
//  AmazingGirlCosmetic
//
//  Created by Алексей Авер on 17.12.2025.
//

import Foundation
import SwiftUI

enum CosmeticCategory: String, Codable, CaseIterable, Identifiable {
    case lipstick = "Lipstick"
    case eyeshadow = "Eyeshadow"
    case powder = "Powder"
    case foundation = "Foundation"
    case mascara = "Mascara" 
    case brows = "Brows"
    case brushes = "Brushes"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .lipstick: return AppColor.red
        case .eyeshadow: return AppColor.violet
        case .powder: return AppColor.orange
        case .foundation: return AppColor.blue
        case .mascara: return AppColor.pink
        case .brows: return AppColor.green
        case .brushes: return AppColor.mint
        }
    }
}

enum CosmeticType: String, Codable, CaseIterable, Identifiable {
    case matte = "Matte"
    case radiant = "Radiant"
    case liquid = "Liquid"
    case powder = "Powder"

    var id: String { rawValue }
}

enum CosmeticStatus: String, Codable, CaseIterable, Identifiable {
    case inUse = "In use"
    case inReserve = "In reserve"

    var id: String { rawValue }
}

struct CosmeticItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: CosmeticCategory
    var type: CosmeticType?
    var status: CosmeticStatus
    var photoData: Data?
}

struct Look: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var note: String?
    var cosmeticIDs: [UUID]
}

struct UsageEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dayKey: String
    var lookIDs: [UUID]
    var cosmeticIDs: [UUID]

    var hasLooks: Bool { !lookIDs.isEmpty }
    var hasCosmetics: Bool { !cosmeticIDs.isEmpty }
}
