//
//  Crafting.swift
//  Nights Of Zahara
//
//  Crafting materials, recipes and their output items. Materials are gathered
//  from dungeons, journeys and treasure; recipes spend materials + dust + gold.
//

import Foundation

struct CraftRecipe: Identifiable {
    var id: String { outputID }
    let outputID: String
    /// materialID -> required count (all consumable material items).
    let materials: [String: Int]
    let dust: Int
    let gold: Int
}

enum CraftCatalog {

    // MARK: Materials (found items, category .material)
    static let materials: [Item] = [
        Item(id: "shadow_dust", name: "Shadow Dust", category: .material, price: 0,
             effect: .none, detail: "Shimmering dark dust from slain monsters.", consumable: true, rarity: .rare, source: .crafting),
        Item(id: "ember_shard", name: "Ember Shard", category: .material, price: 0,
             effect: .none, detail: "A fragment of never-cooling temple fire.", consumable: true, rarity: .rare, source: .crafting),
        Item(id: "sea_glass", name: "Sea Glass", category: .material, price: 0,
             effect: .none, detail: "Glass smoothed by a thousand tides.", consumable: true, rarity: .rare, source: .crafting)
    ]

    // MARK: Craftable output items
    static let outputs: [Item] = [
        Item(id: "charm_warding", name: "Charm of Warding", category: .charm, price: 0,
             effect: .none, detail: "Wards off harm.", consumable: false, rarity: .epic, source: .crafting,
             slot: .charm, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 6)),
        Item(id: "explorer_ring", name: "Explorer's Ring", category: .ring, price: 0,
             effect: .none, detail: "For those who seek hidden places.", consumable: false, rarity: .epic, source: .crafting,
             slot: .ring, equipBonus: Stats(wealth: 0, wisdom: 3, magic: 0, reputation: 0, honor: 0, luck: 4, courage: 0, cunning: 0, endurance: 0)),
        Item(id: "ember_amulet", name: "Ember Amulet", category: .charm, price: 0,
             effect: .none, detail: "Burns with inner fire.", consumable: false, rarity: .legendary, source: .crafting,
             slot: .charm, equipBonus: Stats(wealth: 0, wisdom: 0, magic: 5, reputation: 0, honor: 0, luck: 0, courage: 5, cunning: 0, endurance: 0)),
        Item(id: "healing_draught", name: "Healing Draught", category: .potion, price: 0,
             effect: .healInjury(2), detail: "A potent brew. Heals two injuries.", consumable: true, rarity: .rare, source: .crafting)
    ]

    static let recipes: [CraftRecipe] = [
        CraftRecipe(outputID: "healing_draught", materials: ["shadow_dust": 1], dust: 0, gold: 50),
        CraftRecipe(outputID: "charm_warding", materials: ["shadow_dust": 2], dust: 5, gold: 100),
        CraftRecipe(outputID: "explorer_ring", materials: ["sea_glass": 2], dust: 4, gold: 120),
        CraftRecipe(outputID: "ember_amulet", materials: ["ember_shard": 2], dust: 6, gold: 150)
    ]

    /// A random material id, for drops.
    static func randomMaterialID() -> String {
        materials.randomElement()?.id ?? "shadow_dust"
    }
}
