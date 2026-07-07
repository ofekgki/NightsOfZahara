//
//  Quest.swift
//  Nights Of Zahara
//
//  The general quest log: main, side, dungeon, role, Djinn, companion and
//  treasure quests. (Palace missions live in PalaceQuest / the palace board.)
//

import SwiftUI

enum QuestType: String, Codable, CaseIterable {
    case main, side, dungeon, role, djinn, companion, treasure

    var title: String {
        switch self {
        case .main: return "Main"
        case .side: return "Side"
        case .dungeon: return "Dungeon"
        case .role: return "Role"
        case .djinn: return "Djinn"
        case .companion: return "Companion"
        case .treasure: return "Treasure"
        }
    }
    var icon: String {
        switch self {
        case .main: return "star.fill"
        case .side: return "signpost.right.fill"
        case .dungeon: return "building.columns.fill"
        case .role: return "person.text.rectangle"
        case .djinn: return "flame.fill"
        case .companion: return "person.2.fill"
        case .treasure: return "shippingbox.fill"
        }
    }
    var color: Color {
        switch self {
        case .main: return Theme.brightGold
        case .side: return .cyan
        case .dungeon: return .purple
        case .role: return .orange
        case .djinn: return Theme.ember
        case .companion: return .green
        case .treasure: return Theme.gold
        }
    }
}

struct Quest: Identifiable {
    let id: String
    let type: QuestType
    let name: String
    let description: String
    let objective: QuestObjective
    let rewardGold: Int
    var rewardStat: (StatKind, Int)? = nil
    var rewardItemID: String? = nil
    let risk: RiskLevel
    let location: String
    let npc: String
    let completion: String
    /// When this quest becomes available.
    var available: (GameState) -> Bool = { _ in true }
    /// Only offered to this role, if set.
    var role: Role? = nil
}

enum QuestCatalogGeneral {
    static let all: [Quest] = [
        Quest(id: "sq_first_steps", type: .main,
              name: "First Steps in Zahara",
              description: "Scheherazade urges you to make a name for yourself among the people.",
              objective: .reachReputation(20), rewardGold: 100, rewardStat: (.wisdom, 2),
              risk: .none, location: "Zahara Market", npc: "Scheherazade",
              completion: "\"You are becoming known,\" Scheherazade smiles. \"The city listens now.\""),

        Quest(id: "sq_lost_caravan", type: .side,
              name: "The Lost Caravan",
              description: "A merchant's caravan vanished in the dunes. Brave a journey and search for clues.",
              objective: .findTreasures(4), rewardGold: 160, rewardItemID: "brass_ring",
              risk: .medium, location: "The Deep Desert", npc: "Faruq the Merchant",
              completion: "You recover the caravan's lost goods. Faruq rewards you handsomely."),

        Quest(id: "sq_first_djinn", type: .djinn,
              name: "Echo of the Lamp",
              description: "A whisper from an ancient lamp calls you to bond with your first Djinn.",
              objective: .bondDjinns(1), rewardGold: 200, rewardStat: (.magic, 3),
              risk: .high, location: "A Hidden Dungeon", npc: "Scheherazade",
              completion: "A Djinn now answers your call. Scheherazade nods with quiet pride."),

        Quest(id: "sq_delver", type: .dungeon,
              name: "Delver of the Deep",
              description: "Prove yourself in the dungeons beneath the sands.",
              objective: .conquerDungeons(2), rewardGold: 300, rewardItemID: "star_sapphire",
              risk: .high, location: "The Dungeons", npc: "The Magician Idris",
              completion: "Idris studies your findings. \"Few return from two dungeons. Fewer still, twice victorious.\""),

        Quest(id: "sq_treasure_hoard", type: .treasure,
              name: "The Forty Coins",
              description: "Amass a small fortune through cunning and searching.",
              objective: .amassGold(1000), rewardGold: 0, rewardStat: (.cunning, 3),
              risk: .low, location: "Zahara", npc: "The Thief Rashid",
              completion: "Rashid grins. \"A thousand gold. You have the makings of a guild master.\""),

        // Role-specific quests
        Quest(id: "rq_storyteller", type: .role,
              name: "A Tale for the Ages",
              description: "As a Storyteller, your words are your weapon. Win the city's heart.",
              objective: .reachReputation(45), rewardGold: 220, rewardStat: (.wisdom, 4),
              risk: .low, location: "The Tea House", npc: "Storyteller Nadia",
              completion: "The tea house erupts. Your tale will be retold for a hundred nights.",
              role: .storyteller),
        Quest(id: "rq_sailor", type: .role,
              name: "Call of the Sea",
              description: "As a Sailor, the horizon calls. Endure the long journeys.",
              objective: .reachStat(.endurance, 40), rewardGold: 220, rewardItemID: "nomad_pack",
              risk: .medium, location: "The Port", npc: "Sailor Yusuf",
              completion: "Yusuf claps your shoulder. \"You've the sea in your blood now.\"",
              role: .sailor),
        Quest(id: "rq_wizard", type: .role,
              name: "The Apprentice's Trial",
              description: "As a Wizard Apprentice, master the arcane.",
              objective: .reachStat(.magic, 40), rewardGold: 220, rewardItemID: "spell_book",
              risk: .low, location: "The Magician's Tower", npc: "The Magician Idris",
              completion: "Idris bows slightly. \"You are an apprentice no longer.\"",
              role: .wizardApprentice),
        Quest(id: "rq_merchant", type: .role,
              name: "The Grand Ledger",
              description: "As a Merchant, wealth is your art. Build an empire of coin.",
              objective: .amassGold(1500), rewardGold: 0, rewardStat: (.wealth, 5),
              risk: .low, location: "The Bazaar", npc: "Faruq the Merchant",
              completion: "Faruq names you a partner of the guild.",
              role: .merchant),
        Quest(id: "rq_orphan", type: .role,
              name: "Streets of Gold",
              description: "As a Market Orphan, turn cunning into fortune.",
              objective: .reachStat(.cunning, 35), rewardGold: 220, rewardStat: (.luck, 4),
              risk: .medium, location: "The Back Alleys", npc: "The Thief Rashid",
              completion: "Rashid smirks. \"The streets raised you well.\"",
              role: .marketOrphan)
    ]

    static func quest(id: String) -> Quest? { all.first { $0.id == id } }
}
