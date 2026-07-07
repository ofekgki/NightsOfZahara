//
//  NightAction.swift
//  Nights Of Zahara
//
//  The actions a player can take during a night, with energy cost,
//  icon and risk level metadata used by the action screen.
//

import SwiftUI

enum RiskLevel: String {
    case none = "Safe"
    case low = "Low Risk"
    case medium = "Risky"
    case high = "Dangerous"

    var color: Color {
        switch self {
        case .none:   return Theme.success
        case .low:    return .green
        case .medium: return .orange
        case .high:   return Theme.danger
        }
    }
}

enum NightAction: String, CaseIterable, Identifiable {
    case work, study, train, journey, searchDungeon
    case palace, connections, searchTreasure, rest, shop, upgrade, eat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:           return "Work"
        case .study:          return "Study"
        case .train:          return "Train"
        case .journey:        return "Journey"
        case .searchDungeon:  return "Search for Dungeon"
        case .palace:         return "Enter Palace"
        case .connections:    return "Build Connections"
        case .searchTreasure: return "Search for Treasure"
        case .rest:           return "Rest"
        case .shop:           return "Visit Shop"
        case .upgrade:        return "Upgrade Stats"
        case .eat:            return "Eat Food"
        }
    }

    var icon: String {
        switch self {
        case .work:           return "hammer"
        case .study:          return "book"
        case .train:          return "figure.strengthtraining.traditional"
        case .journey:        return "map"
        case .searchDungeon:  return "magnifyingglass"
        case .palace:         return "building.columns"
        case .connections:    return "person.2.wave.2"
        case .searchTreasure: return "shippingbox"
        case .rest:           return "moon.zzz"
        case .shop:           return "cart"
        case .upgrade:        return "arrow.up.circle"
        case .eat:            return "fork.knife"
        }
    }

    var energyCost: Int {
        switch self {
        case .rest: return 1
        case .work, .study, .train, .palace, .connections, .upgrade: return 2
        case .journey, .searchDungeon, .searchTreasure: return 3
        // Shopping and eating spend gold / consumables rather than energy,
        // so they stay useful (e.g. food that restores energy).
        case .shop, .eat: return 0
        }
    }

    var risk: RiskLevel {
        switch self {
        case .rest, .shop, .eat, .upgrade:      return .none
        case .work, .study, .train, .connections: return .low
        case .searchTreasure, .searchDungeon:   return .medium
        case .journey, .palace:                 return .medium
        }
    }

    var rewardHint: String {
        switch self {
        case .work:           return "Gold & reputation"
        case .study:          return "Wisdom & magic"
        case .train:          return "Courage & endurance"
        case .journey:        return "Treasure, clues, danger"
        case .searchDungeon:  return "Discover a dungeon"
        case .palace:         return "Honor & royal favor"
        case .connections:    return "Reputation & allies"
        case .searchTreasure: return "Gold, gems, items"
        case .rest:           return "Restore energy"
        case .shop:           return "Buy useful goods"
        case .upgrade:        return "Improve a stat"
        case .eat:            return "Restore energy"
        }
    }

    /// Actions handled by opening a dedicated screen rather than instant resolution.
    var opensScreen: Bool {
        switch self {
        case .shop, .upgrade, .eat: return true
        default: return false
        }
    }
}
