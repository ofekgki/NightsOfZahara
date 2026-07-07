//
//  ArtifactCatalog.swift
//  Nights Of Zahara
//
//  Magical artifacts tied to each Djinn, awarded for conquering that Djinn's
//  dungeon. Modeled as equippable Items in the `.artifact` slot.
//

import Foundation

enum ArtifactCatalog {
    /// Artifact item for a given Djinn.
    static func artifact(for djinn: Djinn) -> Item {
        let (id, name, detail, bonus, rarity) = spec(djinn)
        return Item(id: id, name: name, category: .artifact, price: 0,
                    effect: .none, detail: detail, consumable: false,
                    rarity: rarity, source: .djinnArtifact,
                    slot: .artifact, equipBonus: bonus)
    }

    static let all: [Item] = Djinn.allCases.map { artifact(for: $0) }

    static func artifact(id: String) -> Item? { all.first { $0.id == id } }

    private static func spec(_ d: Djinn) -> (String, String, String, Stats, Rarity) {
        func s(_ w: Int = 0, _ wi: Int = 0, _ m: Int = 0, _ r: Int = 0, _ h: Int = 0,
               _ l: Int = 0, _ c: Int = 0, _ cu: Int = 0, _ e: Int = 0) -> Stats {
            Stats(wealth: w, wisdom: wi, magic: m, reputation: r, honor: h, luck: l, courage: c, cunning: cu, endurance: e)
        }
        switch d {
        case .amon:      return ("art_amon", "Ember of Amon", "A coal that never cools. Radiates courage and fire.", s(0,0,4,0,0,0,6,0,0), .legendary)
        case .phenex:    return ("art_phenex", "Feather of Phenex", "A phoenix plume that mends the bearer.", s(0,3,2,0,0,0,0,0,6), .legendary)
        case .vinea:     return ("art_vinea", "Tide Pearl of Vinea", "A pearl that calms any storm.", s(0,0,2,0,0,4,3,0,2), .legendary)
        case .dantalion: return ("art_dantalion", "Lantern of Dantalion", "A lamp that reveals hidden truths.", s(0,7,3,0,0,2,0,0,0), .legendary)
        case .baal:      return ("art_baal", "Rod of Baal", "A rod crackling with stored lightning.", s(0,0,5,0,0,0,6,0,0), .legendary)
        case .zepar:     return ("art_zepar", "Chime of Zepar", "A chime that bends the will of listeners.", s(0,0,0,7,3,0,0,4,0), .legendary)
        case .paimon:    return ("art_paimon", "Sail of Paimon", "A scrap of sail that catches unseen winds.", s(0,0,0,0,0,5,3,3,0), .legendary)
        case .barbatos:  return ("art_barbatos", "Gauntlet of Barbatos", "An iron gauntlet of tremendous might.", s(0,0,0,0,0,0,7,0,6), .legendary)
        case .ugo:       return ("art_ugo", "Keystone of Ugo", "A stone that blesses hearth and home.", s(6,0,0,0,3,0,0,0,4), .legendary)
        case .zagan:     return ("art_zagan", "Seed of Zagan", "A seed that renews all life.", s(0,0,0,0,0,8,0,0,6), .mythic)
        }
    }
}
