//
//  Item.swift
//  Nights Of Zahara
//
//  Shop / inventory items and their effects.
//

import SwiftUI

enum ItemEffect: Codable, Equatable {
    case restoreEnergy(Int)
    case grantStat(StatKind, Int)      // permanent stat gain
    case dungeonKey                     // consumable, aids dungeon search
    case treasureMap                    // reveals a dungeon location
    case luckCharm(Int)                 // permanent luck
}

enum ItemCategory: String, Codable {
    case food, potion, weapon, armor, charm, map, tool, magical

    var icon: String {
        switch self {
        case .food:    return "leaf.fill"
        case .potion:  return "flask"
        case .weapon:  return "shield.lefthalf.filled"
        case .armor:   return "shield"
        case .charm:   return "seal"
        case .map:     return "map"
        case .tool:    return "wrench.and.screwdriver"
        case .magical: return "sparkles"
        }
    }
}

struct Item: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var category: ItemCategory
    var price: Int
    var effect: ItemEffect
    var detail: String
    /// If true the item is consumed on use; otherwise it applies on purchase.
    var consumable: Bool
}

enum ItemCatalog {
    static let all: [Item] = [
        Item(id: "dates", name: "Handful of Dates", category: .food, price: 10,
             effect: .restoreEnergy(1), detail: "Restores 1 energy.", consumable: true),
        Item(id: "warm_meal", name: "Warm Meal", category: .food, price: 25,
             effect: .restoreEnergy(3), detail: "Restores 3 energy.", consumable: true),
        Item(id: "magic_tea", name: "Magic Tea", category: .potion, price: 40,
             effect: .grantStat(.luck, 2), detail: "A soothing brew. +2 Luck.", consumable: false),
        Item(id: "healing_soup", name: "Healing Soup", category: .potion, price: 55,
             effect: .grantStat(.endurance, 3), detail: "Hearty and restorative. +3 Endurance.", consumable: false),
        Item(id: "curved_blade", name: "Curved Blade", category: .weapon, price: 120,
             effect: .grantStat(.courage, 4), detail: "A fine scimitar. +4 Courage.", consumable: false),
        Item(id: "leather_armor", name: "Traveler's Armor", category: .armor, price: 140,
             effect: .grantStat(.endurance, 5), detail: "Worn but sturdy. +5 Endurance.", consumable: false),
        Item(id: "luck_charm", name: "Charm of Fortune", category: .charm, price: 90,
             effect: .luckCharm(3), detail: "An old talisman. +3 Luck.", consumable: false),
        Item(id: "spell_book", name: "Tattered Spell Book", category: .magical, price: 160,
             effect: .grantStat(.magic, 6), detail: "Faded incantations. +6 Magic.", consumable: false),
        Item(id: "treasure_map", name: "Old Treasure Map", category: .map, price: 110,
             effect: .treasureMap, detail: "Reveals a hidden dungeon's location.", consumable: true),
        Item(id: "dungeon_key", name: "Ancient Key", category: .tool, price: 75,
             effect: .dungeonKey, detail: "Improves your next dungeon search.", consumable: true),
        Item(id: "sages_scroll", name: "Sage's Scroll", category: .magical, price: 130,
             effect: .grantStat(.wisdom, 6), detail: "Wisdom of the ancients. +6 Wisdom.", consumable: false),
        Item(id: "silk_robes", name: "Silk Robes", category: .charm, price: 100,
             effect: .grantStat(.reputation, 5), detail: "Fine attire turns heads. +5 Reputation.", consumable: false)
    ]

    static func item(id: String) -> Item? { all.first { $0.id == id } }
}
