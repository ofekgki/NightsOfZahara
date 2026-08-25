//  Al-Mudhib — the legendary King of the Djinns. He is NOT a regular
//  collectible Djinn: his Throne of the Hidden Flame is a secret endgame
//  dungeon that reveals itself only after major late-game progress, and
//  conquering it grants his crown, empowers every Djinn bond, and opens the
//  rarest ending in Zahara.

import SwiftUI

enum KingOfDjinns {
    static let throneID = "throne_hidden_flame"
    static let artifactID = "art_almudhib"

    /// The King's secret endgame dungeon (kept out of DungeonCatalog.all so it
    /// can never be found by an ordinary search).
    static let throneDungeon = Dungeon(
        id: throneID,
        name: "The Throne of the Hidden Flame",
        type: .hiddenFlame,
        djinnReward: nil,
        difficulty: 6,
        rooms: [
            DungeonRoom(name: "The Ancient Seals",        kind: .puzzle,       difficulty: 22),
            DungeonRoom(name: "Royal Djinn Guardians",    kind: .monster,      difficulty: 24),
            DungeonRoom(name: "Echoes of the Conquered",  kind: .trap,         difficulty: 23),
            DungeonRoom(name: "Trial of Your Choices",    kind: .puzzle,       difficulty: 24),
            DungeonRoom(name: "Al-Mudhib, King of the Djinns", kind: .boss,    difficulty: 30),
            DungeonRoom(name: "The Hidden Flame",         kind: .djinnChamber, difficulty: 20)
        ],
        goldReward: 1500,
        icon: "flame.fill")

    /// The King's crown — a mythic artifact that empowers every Djinn bond.
    static let artifact = Item(
        id: artifactID, name: "Crown of Al-Mudhib", category: .artifact, price: 0,
        effect: .none,
        detail: "The crown of the King of the Djinns. It empowers every Djinn you have bonded and marks its bearer as sovereign of the hidden flame.",
        consumable: false, rarity: .mythic, source: .djinnArtifact, slot: .artifact,
        equipBonus: Stats(wealth: 0, wisdom: 10, magic: 12, reputation: 5, honor: 8,
                          luck: 0, courage: 5, cunning: 0, endurance: 5))

    static let lore = "Al-Mudhib, the King of the Djinns, rules the hidden flame from which all Djinns were kindled. He does not answer to lamp or ring; he judges those who would command his kind. Only a soul who has bonded many Djinns, earned the trust of Scheherazade and King Sinbad, walked far into the thousand nights, and made their choices with wisdom and honor may find his throne. Those who conquer his final trial are crowned sovereign of the Djinns — and their legend outlasts Zahara itself."

    // MARK: - State

    /// Whether the throne has revealed itself and can be entered.
    /// Requires broad mastery — at least three stats of 85+, though not every
    /// stat need reach 85 — plus deep bonds and meaningful choices.
    static func isUnlocked(_ s: GameState) -> Bool {
        let highStats = StatKind.allCases.filter { s.stats[$0] >= 85 }.count
        return s.night >= 70
            && s.completedDungeons.count >= 15
            && s.meta.relationship("scheherazade") >= 15
            && s.meta.relationship("sinbad") >= 15
            && highStats >= 3
            && !s.meta.majorChoices.isEmpty
    }

    /// Whether the player has conquered the throne and bonded the King.
    static func isBonded(_ s: GameState) -> Bool {
        s.completedDungeons.contains(throneID)
    }
}
