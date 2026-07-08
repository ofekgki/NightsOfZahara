//
//  Item.swift
//  Nights Of Zahara
//
//  Shop / inventory items: effects, categories, rarity, source and equipment.
//

import SwiftUI

enum ItemEffect: Codable, Equatable {
    case restoreEnergy(Int)
    case grantStat(StatKind, Int)      // permanent stat gain (on use / on acquire)
    case dungeonKey                     // consumable, aids dungeon search
    case treasureMap                    // reveals a dungeon location
    case luckCharm(Int)                 // permanent luck
    case healInjury(Int)                // reduces injuries
    case none                           // equippables, materials, quest items

    /// A plain-language explanation of what the effect does (for info tooltips).
    var explanation: String {
        switch self {
        case .restoreEnergy(let n): return "Restores \(n) energy when used."
        case .grantStat(let k, let n): return "Permanently grants +\(n) \(k.title)."
        case .dungeonKey:           return "Sharpens your next dungeon search (grants clues)."
        case .treasureMap:          return "Reveals the location of a hidden dungeon."
        case .luckCharm(let n):     return "Permanently grants +\(n) Luck."
        case .healInjury(let n):    return "Heals \(n) injur\(n == 1 ? "y" : "ies")."
        case .none:                 return "No direct effect."
        }
    }
}

enum ItemCategory: String, Codable {
    case food, potion, weapon, armor, charm, ring, map, tool, magical, material, quest, artifact

    var icon: String {
        switch self {
        case .food:     return "leaf.fill"
        case .potion:   return "flask"
        case .weapon:   return "shield.lefthalf.filled"
        case .armor:    return "shield"
        case .charm:    return "seal"
        case .ring:     return "circle.circle"
        case .map:      return "map"
        case .tool:     return "wrench.and.screwdriver"
        case .magical:  return "sparkles"
        case .material: return "cube"
        case .quest:    return "scroll"
        case .artifact: return "wand.and.stars"
        }
    }
}

/// Equipment slots a piece of gear can occupy.
enum EquipmentSlot: String, Codable, CaseIterable, Identifiable {
    case weapon, armor, charm, ring, artifact, travel
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .weapon:   return "shield.lefthalf.filled"
        case .armor:    return "shield"
        case .charm:    return "seal"
        case .ring:     return "circle.circle"
        case .artifact: return "wand.and.stars"
        case .travel:   return "backpack"
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
    /// If true the item is consumed on use; otherwise it is unique & permanent.
    var consumable: Bool
    var rarity: Rarity = .common
    var source: ItemSource = .shop
    /// If set, the item can be equipped in this slot.
    var slot: EquipmentSlot? = nil
    /// Stat bonus granted while equipped (equippable items only).
    var equipBonus: Stats? = nil

    var isEquippable: Bool { slot != nil }

    /// A short "+4 Courage, -2 Speed" style summary of the equip bonus.
    var equipSummary: String {
        guard let b = equipBonus else { return "" }
        let parts: [String] = StatKind.allCases.compactMap { k in
            let v = b[k]
            return v != 0 ? "\(v > 0 ? "+" : "")\(v) \(k.title)" : nil
        }
        return parts.joined(separator: ", ")
    }

    /// A full info-tooltip explanation of what this item does.
    var infoText: String {
        if isEquippable {
            let s = equipSummary
            return s.isEmpty ? detail : "\(detail)\nWhile equipped: \(s)."
        }
        if case .none = effect { return detail }
        return "\(detail)\n\(effect.explanation)"
    }
}

enum ItemCatalog {
    static let all: [Item] = shopItems + searchItems + dungeonGear + questItems
        + ArtifactCatalog.all + CraftCatalog.materials + CraftCatalog.outputs

    // MARK: Shop-only
    static let shopItems: [Item] = [
        // The single energy-restoring food. Deliberately costly and capped at
        // +2 energy so it never becomes a cheap fountain of free actions.
        Item(id: "warm_meal", name: "Hearty Feast", category: .food, price: 150,
             effect: .restoreEnergy(2), detail: "A rich, restoring meal. Restores exactly 2 energy.", consumable: true, rarity: .common, source: .shop),
        Item(id: "magic_tea", name: "Magic Tea", category: .potion, price: 40,
             effect: .grantStat(.luck, 2), detail: "A soothing brew. +2 Luck when drunk.", consumable: true, rarity: .rare, source: .shop),
        Item(id: "healing_soup", name: "Healing Soup", category: .potion, price: 55,
             effect: .healInjury(1), detail: "Mends wounds. Heals an injury.", consumable: true, rarity: .rare, source: .shop),
        Item(id: "curved_blade", name: "Curved Blade", category: .weapon, price: 120,
             effect: .none, detail: "A fine scimitar.", consumable: false, rarity: .rare, source: .shop,
             slot: .weapon, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 4, cunning: 0, endurance: 0, speed: -1)),
        Item(id: "leather_armor", name: "Traveler's Armor", category: .armor, price: 140,
             effect: .none, detail: "Worn but sturdy.", consumable: false, rarity: .rare, source: .shop,
             slot: .armor, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 5, speed: -2)),
        Item(id: "luck_charm", name: "Charm of Fortune", category: .charm, price: 90,
             effect: .none, detail: "An old talisman.", consumable: false, rarity: .rare, source: .shop,
             slot: .charm, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 3, courage: 0, cunning: 0, endurance: 0)),
        Item(id: "spell_book", name: "Tattered Spell Book", category: .magical, price: 160,
             effect: .grantStat(.magic, 6), detail: "Faded incantations. +6 Magic (permanent).", consumable: false, rarity: .epic, source: .shop),
        Item(id: "treasure_map", name: "Old Treasure Map", category: .map, price: 110,
             effect: .treasureMap, detail: "Reveals a hidden dungeon's location.", consumable: true, rarity: .rare, source: .shop),
        Item(id: "dungeon_key", name: "Ancient Key", category: .tool, price: 75,
             effect: .dungeonKey, detail: "Improves your next dungeon search.", consumable: true, rarity: .common, source: .shop),
        Item(id: "sages_scroll", name: "Sage's Scroll", category: .magical, price: 130,
             effect: .grantStat(.wisdom, 6), detail: "Wisdom of the ancients. +6 Wisdom (permanent).", consumable: false, rarity: .epic, source: .shop),
        Item(id: "silk_robes", name: "Silk Robes", category: .charm, price: 100,
             effect: .none, detail: "Fine attire turns heads.", consumable: false, rarity: .rare, source: .shop,
             slot: .armor, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 5, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 0))
    ]

    // MARK: Search-only (treasure / journeys / events)
    static let searchItems: [Item] = [
        Item(id: "brass_ring", name: "Brass Ring of Wandering", category: .ring, price: 0,
             effect: .none, detail: "Found in the sand.", consumable: false, rarity: .rare, source: .search,
             slot: .ring, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 2, courage: 0, cunning: 2, endurance: 0)),
        Item(id: "nomad_pack", name: "Nomad's Pack", category: .tool, price: 0,
             effect: .none, detail: "A well-made travel pack.", consumable: false, rarity: .rare, source: .search,
             slot: .travel, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 3)),
        Item(id: "star_sapphire", name: "Star Sapphire", category: .magical, price: 0,
             effect: .grantStat(.magic, 4), detail: "A gem humming with power. +4 Magic.", consumable: false, rarity: .epic, source: .search)
    ]

    // MARK: Dungeon rewards (gear)
    static let dungeonGear: [Item] = [
        Item(id: "guardian_blade", name: "Guardian's Blade", category: .weapon, price: 0,
             effect: .none, detail: "Taken from a fallen dungeon guardian.", consumable: false, rarity: .epic, source: .dungeon,
             slot: .weapon, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 6, cunning: 0, endurance: 2, speed: -1)),
        Item(id: "warden_plate", name: "Warden's Plate", category: .armor, price: 0,
             effect: .none, detail: "Heavy armor of an ancient warden.", consumable: false, rarity: .epic, source: .dungeon,
             slot: .armor, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 8, speed: -4))
    ]

    // MARK: Quest items
    static let questItems: [Item] = [
        Item(id: "royal_seal", name: "Royal Seal of Sinbad", category: .quest, price: 0,
             effect: .none, detail: "A token of the king's trust.", consumable: false, rarity: .legendary, source: .quest)
    ]

    static func item(id: String) -> Item? { all.first { $0.id == id } }
}
