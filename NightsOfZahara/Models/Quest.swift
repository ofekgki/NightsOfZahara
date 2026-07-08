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
              role: .marketOrphan),

        // Quests unlocked when a faction or key figure warms to you (Friendly+).
        Quest(id: "fq_merchants", type: .side,
              name: "The Merchant's Trust",
              description: "The Merchants' Guild counts you a friend. Prove your worth in trade.",
              objective: .amassGold(800), rewardGold: 150, rewardStat: (.wealth, 3),
              risk: .none, location: "The Bazaar", npc: "Merchants' Guild",
              completion: "The guild toasts your fortune and opens its ledgers to you.",
              available: { ($0._meta?.faction("merchants") ?? 0) >= 10 }),

        Quest(id: "fq_sailors", type: .side,
              name: "Charted Waters",
              description: "The Sailors of the Port trust you now. Brave the far routes and bring back proof.",
              objective: .findTreasures(8), rewardGold: 180, rewardItemID: "nomad_pack",
              risk: .medium, location: "The Port", npc: "Sailors of the Port",
              completion: "The sailors sing your name in the dockside taverns.",
              available: { ($0._meta?.faction("sailors") ?? 0) >= 10 }),

        Quest(id: "fq_thieves", type: .side,
              name: "A Thief's Pact",
              description: "The Thieves' Guild welcomes you into the shadows. Show your cunning.",
              objective: .reachStat(.cunning, 30), rewardGold: 200, rewardStat: (.luck, 3),
              risk: .medium, location: "The Back Alleys", npc: "Thieves' Guild",
              completion: "The guild marks you as one of their own.",
              available: { ($0._meta?.faction("thieves") ?? 0) >= 10 }),

        Quest(id: "fq_scheherazade", type: .main,
              name: "The Sorceress's Confidence",
              description: "Scheherazade sees greatness in you. Master the arcane to earn her deepest trust.",
              objective: .reachStat(.magic, 30), rewardGold: 200, rewardStat: (.wisdom, 4),
              risk: .low, location: "Scheherazade's Tower", npc: "Scheherazade",
              completion: "Scheherazade shares a secret of the Djinns with you alone.",
              available: { ($0._meta?.relationship("scheherazade") ?? 0) >= 25 }),

        Quest(id: "fq_sinbad", type: .side,
              name: "The King's Confidant",
              description: "King Sinbad has grown to trust you. Rise in honor to serve at his side.",
              objective: .reachHonor(35), rewardGold: 220, rewardStat: (.honor, 3),
              risk: .low, location: "Sinbad's Palace", npc: "King Sinbad",
              completion: "Sinbad names you among his most trusted advisors.",
              available: { ($0._meta?.relationship("sinbad") ?? 0) >= 10 }),

        // ── Ali Baba's questline (treasure & hidden caves) ──
        Quest(id: "ab_rumor", type: .treasure,
              name: "A Merchant's Whisper",
              description: "Ali Baba shares a rumor of coin buried beneath the dunes. Prove your treasure-hunter's nose.",
              objective: .findTreasures(6), rewardGold: 180, rewardStat: (.luck, 2),
              risk: .low, location: "The Bazaar", npc: "Ali Baba",
              completion: "Ali Baba grins. \"You've the nose of a true treasure hunter.\"",
              available: { ($0._meta?.relationship("alibaba") ?? 0) >= 10 }),
        Quest(id: "ab_cave", type: .treasure,
              name: "The Forty Thieves' Cave",
              description: "Ali Baba trusts you with the way to a hidden cave. Sharpen your cunning to claim its hoard.",
              objective: .reachStat(.cunning, 30), rewardGold: 300, rewardItemID: "brass_ring",
              risk: .high, location: "The Hidden Cave", npc: "Ali Baba",
              completion: "\"Open Sesame,\" Ali Baba laughs. \"The cave was yours all along.\"",
              available: { ($0._meta?.relationship("alibaba") ?? 0) >= 25 }),
        Quest(id: "ab_legend", type: .treasure,
              name: "The Cave of the Forty Fortunes",
              description: "At the height of your friendship, Ali Baba reveals the greatest hoard in the desert — if your fortune is vast enough to match it.",
              objective: .amassGold(2500), rewardGold: 0, rewardStat: (.luck, 6),
              risk: .high, location: "The Deep Desert", npc: "Ali Baba",
              completion: "The cave's gold is beyond counting. Ali Baba names you his equal.",
              available: { ($0._meta?.relationship("alibaba") ?? 0) >= 80 }),

        // ── Jasmine's questline (palace & diplomacy) ──
        Quest(id: "jz_people", type: .main,
              name: "Voice of the People",
              description: "Jasmine asks you to win the goodwill of Zahara's common folk.",
              objective: .reachReputation(35), rewardGold: 160, rewardStat: (.honor, 3),
              risk: .none, location: "The Markets", npc: "Jasmine",
              completion: "\"The people speak your name kindly now,\" Jasmine says.",
              available: { ($0._meta?.relationship("jasmine") ?? 0) >= 10 }),
        Quest(id: "jz_peace", type: .side,
              name: "A Fragile Peace",
              description: "Jasmine seeks a diplomat's hand to settle a feud among the nobles without bloodshed.",
              objective: .reachHonor(40), rewardGold: 240, rewardStat: (.reputation, 4),
              risk: .low, location: "Sinbad's Palace", npc: "Jasmine",
              completion: "The feud ends without a drawn blade. Jasmine is deeply grateful.",
              available: { ($0._meta?.relationship("jasmine") ?? 0) >= 25 }),
        Quest(id: "jz_protector", type: .main,
              name: "Protector of Zahara",
              description: "Jasmine believes you could be the shield the city needs. Become the most honored soul in Zahara.",
              objective: .reachHonor(70), rewardGold: 400, rewardStat: (.reputation, 6),
              risk: .low, location: "Sinbad's Palace", npc: "Jasmine",
              completion: "The people hail you as protector. Jasmine smiles: \"Zahara is safe with you.\"",
              available: { ($0._meta?.relationship("jasmine") ?? 0) >= 80 }),

        // ── Aladdin's questline (magic & Djinn artifacts) ──
        Quest(id: "al_rumor", type: .side,
              name: "Street Rumors",
              description: "Aladdin has heard whispers of magic in the market shadows. Grow your own arcane gift.",
              objective: .reachStat(.magic, 20), rewardGold: 170, rewardItemID: "star_sapphire",
              risk: .medium, location: "The Back Alleys", npc: "Aladdin",
              completion: "Aladdin tosses you a gem. \"Told you the streets keep secrets.\"",
              available: { ($0._meta?.relationship("aladdin") ?? 0) >= 10 }),
        Quest(id: "al_wonders", type: .djinn,
              name: "The Cave of Wonders",
              description: "Aladdin believes a Djinn artifact waits in the deep dark. Bond with the Djinns to prove the way.",
              objective: .bondDjinns(2), rewardGold: 320, rewardStat: (.magic, 4),
              risk: .high, location: "The Cave of Wonders", npc: "Aladdin",
              completion: "A lamp lies warm in your hands. Aladdin's eyes shine with wonder.",
              available: { ($0._meta?.relationship("aladdin") ?? 0) >= 25 }),
        Quest(id: "al_ring_djinn", type: .djinn,
              name: "The Ring Djinn's Riddle",
              description: "At the height of your bond, Aladdin reveals a second lamp — and the Djinn of the Ring it hides. Master the Djinns to earn it.",
              objective: .bondDjinns(4), rewardGold: 500, rewardStat: (.magic, 6),
              risk: .high, location: "The Cave of Wonders", npc: "Aladdin",
              completion: "The Ring Djinn bows to you both. A legend among legends is written.",
              available: { ($0._meta?.relationship("aladdin") ?? 0) >= 80 })
    ]

    static func quest(id: String) -> Quest? { all.first { $0.id == id } }
}
