//  Royal missions granted by King Sinbad in the palace. Each quest sets a
//  goal; when the goal is met the player may claim gold and honor.

import Foundation

enum QuestObjective: Codable, Equatable {
    case reachReputation(Int)
    case reachHonor(Int)
    case amassGold(Int)
    case conquerDungeons(Int)
    case bondDjinns(Int)
    case findTreasures(Int)
    case reachStat(StatKind, Int)
    case ownItem(String)

    /// How far along the player is, as (current, target).
    func progress(in s: GameState) -> (current: Int, target: Int) {
        switch self {
        case .reachReputation(let t): return (s.stats.reputation, t)
        case .reachHonor(let t):      return (s.stats.honor, t)
        case .amassGold(let t):       return (s.gold, t)
        case .conquerDungeons(let t): return (s.completedDungeons.count, t)
        case .bondDjinns(let t):      return (s.djinns.count, t)
        case .findTreasures(let t):   return (s.treasuresFound, t)
        case .reachStat(let k, let t): return (s.stats[k], t)
        case .ownItem(let id):        return ((s.inventory[id] ?? 0) > 0 ? 1 : 0, 1)
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
        case .reachStat(let k, let t): return "Reach \(t) \(k.title)"
        case .ownItem(let id):        return "Obtain \(ItemCatalog.item(id: id)?.name ?? id)"
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
                    rewardGold: 70, rewardHonor: 3, rewardReputation: 0),
        PalaceQuest(id: "q_treasures",
                    title: "The Royal Collection",
                    flavor: "\"Bring glory to Zahara. Recover treasures worthy of the palace vaults.\"",
                    objective: .findTreasures(6),
                    rewardGold: 100, rewardHonor: 3, rewardReputation: 2),
        PalaceQuest(id: "q_first_dungeon",
                    title: "Trial of Courage",
                    flavor: "\"I was a sailor before a king,\" Sinbad muses. \"Prove your courage — conquer a Djinn's dungeon.\"",
                    objective: .conquerDungeons(1),
                    rewardGold: 140, rewardHonor: 6, rewardReputation: 3),
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
                    rewardGold: 900, rewardHonor: 25, rewardReputation: 20),

        // ── The King's late-game commissions (only stay relevant deep into a run) ──
        PalaceQuest(id: "q_king_treasury",
                    title: "The Royal Treasury",
                    flavor: "\"Zahara's coffers must dwarf any rival kingdom's,\" Sinbad decrees. \"Amass a fortune worthy of a throne.\"",
                    objective: .amassGold(4000),
                    rewardGold: 0, rewardHonor: 20, rewardReputation: 18),
        PalaceQuest(id: "q_king_scourge",
                    title: "Scourge of the Deep",
                    flavor: "\"Ten dungeons have swallowed my finest sailors whole. Clear them, and Zahara will sleep without fear.\"",
                    objective: .conquerDungeons(10),
                    rewardGold: 1400, rewardHonor: 30, rewardReputation: 22),
        PalaceQuest(id: "q_king_paragon",
                    title: "Paragon of the Realm",
                    flavor: "\"There is no honor left in this city greater than yours to claim. Become its very measure.\"",
                    objective: .reachHonor(90),
                    rewardGold: 1000, rewardHonor: 0, rewardReputation: 25),
        PalaceQuest(id: "q_king_conclave",
                    title: "The Djinn Conclave",
                    flavor: "\"Scheherazade tells of a court of Djinns bound to one soul. Bind twelve, and no ruler on earth will be your equal.\"",
                    objective: .bondDjinns(12),
                    rewardGold: 2000, rewardHonor: 35, rewardReputation: 30),
        PalaceQuest(id: "q_king_champion",
                    title: "Champion of Zahara",
                    flavor: "\"My kingdom needs a champion whose strength is beyond question. Forge your body into a legend of endurance.\"",
                    objective: .reachStat(.endurance, 95),
                    rewardGold: 1200, rewardHonor: 28, rewardReputation: 20),
        PalaceQuest(id: "q_king_sovereign",
                    title: "The Sovereign's Equal",
                    flavor: "\"When your name is spoken in every port from here to the edge of the world, you will have earned your place beside me.\"",
                    objective: .reachReputation(95),
                    rewardGold: 2500, rewardHonor: 40, rewardReputation: 0)
    ]

    static func quest(id: String) -> PalaceQuest? { all.first { $0.id == id } }
}
