//
//  Companion.swift
//  Nights Of Zahara
//
//  NPC companions the player can recruit in Zahara. Each grants a passive
//  bonus and has a personal companion quest.
//

import SwiftUI

enum CompanionBonusKind: String, Codable {
    case combat, treasure, dungeonSafety, shopDiscount, puzzle, faction, reputation

    var label: String {
        switch self {
        case .combat:        return "Combat power"
        case .treasure:      return "Treasure fortune"
        case .dungeonSafety:  return "Dungeon safety"
        case .shopDiscount:  return "Shop discount"
        case .puzzle:        return "Puzzle solving"
        case .faction:       return "Faction favor"
        case .reputation:    return "Reputation gain"
        }
    }
}

struct Companion: Identifiable {
    let id: String
    let name: String
    let role: String
    let personality: String
    let bonusKind: CompanionBonusKind
    let bonusAmount: Int
    let recruitCost: Int
    let unlockHint: String
    let questText: String
    /// When the companion can be recruited.
    let unlock: (GameState) -> Bool
}

enum CompanionCatalog {
    static let all: [Companion] = [
        Companion(id: "amina", name: "Amina the Healer", role: "Healer",
                  personality: "Gentle, wise, endlessly patient.",
                  bonusKind: .dungeonSafety, bonusAmount: 3, recruitCost: 150,
                  unlockHint: "Build a Guest Room.",
                  questText: "Amina seeks rare desert herbs to restock her remedies.",
                  unlock: { ($0._meta?.homeRooms["guest"] ?? 0) >= 1 }),

        Companion(id: "rashid", name: "Rashid the Thief", role: "Rogue",
                  personality: "Sly, quick-fingered, secretly loyal.",
                  bonusKind: .treasure, bonusAmount: 6, recruitCost: 200,
                  unlockHint: "Earn the Thieves' Guild's favor (Friendly).",
                  questText: "Rashid needs a lookout for one last, lucrative job.",
                  unlock: { ($0._meta?.faction("thieves") ?? 0) >= 10 }),

        Companion(id: "yusuf", name: "Yusuf the Sailor", role: "Sailor",
                  personality: "Boisterous, brave, full of sea tales.",
                  bonusKind: .combat, bonusAmount: 4, recruitCost: 180,
                  unlockHint: "Befriend the Sailors of the Port (Friendly).",
                  questText: "Yusuf dreams of one last voyage to a fabled island.",
                  unlock: { ($0._meta?.faction("sailors") ?? 0) >= 10 }),

        Companion(id: "idris", name: "Idris the Magician", role: "Magician",
                  personality: "Aloof, brilliant, quietly kind.",
                  bonusKind: .puzzle, bonusAmount: 5, recruitCost: 260,
                  unlockHint: "Bond with at least one Djinn.",
                  questText: "Idris asks your help translating a forbidden grimoire.",
                  unlock: { !$0.djinns.isEmpty }),

        Companion(id: "layla", name: "Captain Layla", role: "Palace Guard",
                  personality: "Disciplined, honorable, fiercely protective.",
                  bonusKind: .faction, bonusAmount: 3, recruitCost: 300,
                  unlockHint: "Gain the palace's trust (unlock the palace).",
                  questText: "Layla suspects a traitor within the palace walls.",
                  unlock: { $0.palaceUnlocked })
    ]

    static func companion(id: String) -> Companion? { all.first { $0.id == id } }
}
