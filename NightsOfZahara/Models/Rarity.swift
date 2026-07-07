//
//  Rarity.swift
//  Nights Of Zahara
//
//  Item rarity tiers and where an item may be obtained.
//

import SwiftUI

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common, rare, epic, legendary, mythic

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .common:    return Color(white: 0.75)
        case .rare:      return .cyan
        case .epic:      return .purple
        case .legendary: return Theme.brightGold
        case .mythic:    return Theme.ember
        }
    }

    /// Multiplier on sell value / dust yield.
    var valueMultiplier: Int {
        switch self {
        case .common: return 1
        case .rare: return 2
        case .epic: return 4
        case .legendary: return 8
        case .mythic: return 15
        }
    }

    private var order: Int { Rarity.allCases.firstIndex(of: self)! }
    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.order < rhs.order }
}

/// Where an item can come from — drives the "Shop-only / Search-only / …" grouping.
enum ItemSource: String, Codable, CaseIterable {
    case shop            // shop-only
    case search          // found via treasure/journey/events/dungeon
    case dungeon         // dungeon victory rewards
    case djinnArtifact   // magical artifacts tied to a Djinn
    case crafting        // crafting materials
    case quest           // quest items

    var label: String {
        switch self {
        case .shop: return "Shop"
        case .search: return "Found"
        case .dungeon: return "Dungeon"
        case .djinnArtifact: return "Artifact"
        case .crafting: return "Material"
        case .quest: return "Quest"
        }
    }

    var icon: String {
        switch self {
        case .shop: return "cart"
        case .search: return "sparkle.magnifyingglass"
        case .dungeon: return "building.columns"
        case .djinnArtifact: return "wand.and.stars"
        case .crafting: return "hammer"
        case .quest: return "scroll"
        }
    }
}
