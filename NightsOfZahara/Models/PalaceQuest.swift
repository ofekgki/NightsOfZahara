//
//  PalaceQuest.swift
//  Nights Of Zahara
//
//  Royal missions granted by King Sinbad in the palace. Each quest sets a
//  goal; when the goal is met the player may claim gold and honor.
//

import Foundation

enum QuestObjective: Codable, Equatable {
    case reachReputation(Int)
    case reachHonor(Int)
    case amassGold(Int)
    case conquerDungeons(Int)
    case bondDjinns(Int)
    case findTreasures(Int)

    /// How far along the player is, as (current, target).
    func progress(in s: GameState) -> (current: Int, target: Int) {
        switch self {
        case .reachReputation(let t): return (s.stats.reputation, t)
        case .reachHonor(let t):      return (s.stats.honor, t)
        case .amassGold(let t):       return (s.gold, t)
        case .conquerDungeons(let t): return (s.completedDungeons.count, t)
        case .bondDjinns(let t):      return (s.djinns.count, t)
        case .findTreasures(let t):   return (s.treasuresFound, t)
        }
    }

    func isSatisfied(in s: GameState) -> Bool {
        let p = progress(in: s)
        return p.current >= p.target
    }

    var label: String {
        switch self {
        case .reachReputation(let t): return "Reach \(t) Reputation"
        case .reachHonor(let t):      return "Reach \(t) Honor"
        case .amassGold(let t):       return "Hold \(t) Gold at once"
        case .conquerDungeons(let t): return "Conquer \(t) dungeons"
        case .bondDjinns(let t):      return "Bond with \(t) Djinns"
        case .findTreasures(let t):   return "Find \(t) treasures"
        }
    }
}

struct PalaceQuest: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var flavor: String
    var objective: QuestObjective
    var rewardGold: Int
    var rewardHonor: Int
    var rewardReputation: Int
}

enum QuestCatalog {
    /// King Sinbad's roster of royal missions, ordered from humble to grand.
    static let all: [PalaceQuest] = [
        PalaceQuest(id: "q_reputation",
                    title: "A Name Worth Knowing",
                    flavor: "\"Make yourself known in my city,\" says Sinbad. \"A king should hear your name in the markets.\"",
                    objective: .reachReputation(30),
                    rewardGold: 120, rewardHonor: 5, rewardReputation: 0),
        PalaceQuest(id: "q_treasures",
                    title: "The Royal Collection",
                    flavor: "\"Bring glory to Zahara. Recover treasures worthy of the palace vaults.\"",
                    objective: .findTreasures(6),
                    rewardGold: 160, rewardHonor: 4, rewardReputation: 3),
        PalaceQuest(id: "q_first_dungeon",
                    title: "Trial of Courage",
                    flavor: "\"I was a sailor before a king,\" Sinbad muses. \"Prove your courage — conquer a Djinn's dungeon.\"",
                    objective: .conquerDungeons(1),
                    rewardGold: 200, rewardHonor: 8, rewardReputation: 4),
        PalaceQuest(id: "q_gold",
                    title: "The King's Confidence",
                    flavor: "\"A trusted hand must handle wealth wisely. Show me you can amass a fortune.\"",
                    objective: .amassGold(1200),
                    rewardGold: 0, rewardHonor: 10, rewardReputation: 6),
        PalaceQuest(id: "q_djinns",
                    title: "Keeper of Djinns",
                    flavor: "\"Scheherazade speaks of ancient Djinns. Bond with three, and I shall name you a hero of the realm.\"",
                    objective: .bondDjinns(3),
                    rewardGold: 400, rewardHonor: 15, rewardReputation: 10),
        PalaceQuest(id: "q_honor",
                    title: "Right Hand of the King",
                    flavor: "\"Become the most honored soul in Zahara, and a seat at my court is yours.\"",
                    objective: .reachHonor(60),
                    rewardGold: 300, rewardHonor: 0, rewardReputation: 12),
        PalaceQuest(id: "q_master",
                    title: "Legend of the Thousand Nights",
                    flavor: "\"Conquer six dungeons and claim their Djinns. Do this, and your legend will outlive us both.\"",
                    objective: .conquerDungeons(6),
                    rewardGold: 900, rewardHonor: 25, rewardReputation: 20)
    ]

    static func quest(id: String) -> PalaceQuest? { all.first { $0.id == id } }
}
