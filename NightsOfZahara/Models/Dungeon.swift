//
//  Dungeon.swift
//  Nights Of Zahara
//
//  Dungeon definitions: types, rooms and the starter dungeons that can
//  be discovered and conquered to bond with a Djinn.
//

import SwiftUI

enum DungeonType: String, Codable {
    case desertCave      = "Desert Cave"
    case ancientTemple   = "Ancient Temple"
    case shipwreck       = "Shipwreck"
    case wizardTower     = "Wizard Tower"
    case catacombs       = "Catacombs"
    case abandonedPalace = "Abandoned Palace"

    var icon: String {
        switch self {
        case .desertCave:      return "mountain.2"
        case .ancientTemple:   return "building.columns"
        case .shipwreck:       return "ferry"
        case .wizardTower:     return "building"
        case .catacombs:       return "skull"
        case .abandonedPalace: return "crown"
        }
    }
}

enum RoomKind: String, Codable, CaseIterable {
    case monster, puzzle, trap, treasure, boss, djinnChamber

    var icon: String {
        switch self {
        case .monster:      return "pawprint"
        case .puzzle:       return "puzzlepiece"
        case .trap:         return "exclamationmark.triangle"
        case .treasure:     return "shippingbox"
        case .boss:         return "crown.fill"
        case .djinnChamber: return "sparkles"
        }
    }

    /// Which stat is primarily tested in this room.
    var testedStat: StatKind {
        switch self {
        case .monster:      return .courage
        case .puzzle:       return .wisdom
        case .trap:         return .cunning
        case .treasure:     return .luck
        case .boss:         return .endurance
        case .djinnChamber: return .magic
        }
    }
}

struct DungeonRoom: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: RoomKind
    /// Difficulty threshold for the tested stat check.
    var difficulty: Int
}

struct Dungeon: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var type: DungeonType
    var djinnReward: Djinn?
    var difficulty: Int          // 1 (easy) ... 5 (deadly)
    var rooms: [DungeonRoom]
    var goldReward: Int
    /// Optional custom icon overriding the dungeon type's default.
    var icon: String? = nil

    /// The icon to show for this dungeon (custom override, else its type's).
    var displayIcon: String { icon ?? type.icon }

    var difficultyLabel: String {
        switch difficulty {
        case ...1: return "Easy"
        case 2:    return "Modest"
        case 3:    return "Hard"
        case 4:    return "Perilous"
        default:   return "Deadly"
        }
    }

    /// The distinct stats this dungeon's rooms will test.
    var testedStats: [StatKind] {
        var seen: [StatKind] = []
        for room in rooms where !seen.contains(room.kind.testedStat) {
            seen.append(room.kind.testedStat)
        }
        return seen
    }

    /// A recommended minimum for each tested stat, scaled by difficulty.
    var recommendedStats: [(StatKind, Int)] {
        let target = 10 + difficulty * 6
        return testedStats.map { ($0, target) }
    }

    /// Recommended endurance to survive the crawl.
    var recommendedEndurance: Int { 12 + difficulty * 7 }

    /// Short human summary of what conquering it yields.
    var rewardSummary: String {
        var parts = ["\(goldReward) gold"]
        if let d = djinnReward { parts.append("the Djinn \(d.name)"); parts.append("its artifact") }
        parts.append("a chance at gear & materials")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Starter dungeon catalog

enum DungeonCatalog {

    /// All dungeons that exist in the game world — one per Djinn.
    static let all: [Dungeon] = [
        healingTemple, sunkenGalleon, caveOfWhispers,     // difficulty 2
        templeOfFire, towerOfDawn, hallOfEchoes, deepFoundations, // difficulty 3
        cavernOfStrength, stormSpire,                     // difficulty 4
        gardenOfRenewal                                   // difficulty 5
    ]

    static func dungeon(id: String) -> Dungeon? {
        all.first { $0.id == id }
    }

    /// The dungeon that rewards a given Djinn, if any.
    static func dungeon(forDjinn djinn: Djinn) -> Dungeon? {
        all.first { $0.djinnReward == djinn }
    }

    /// Amon — Temple of Fire (from the spec's worked example).
    static let templeOfFire = Dungeon(
        id: "temple_of_fire",
        name: "Temple of Fire",
        type: .ancientTemple,
        djinnReward: .amon,
        difficulty: 3,
        rooms: [
            DungeonRoom(name: "Gate of Ash",         kind: .trap,        difficulty: 12),
            DungeonRoom(name: "Torch Chamber",       kind: .monster,     difficulty: 14),
            DungeonRoom(name: "Fire Guardian",       kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Ancient Fire Puzzle", kind: .puzzle,      difficulty: 16),
            DungeonRoom(name: "Lava Hall",           kind: .trap,        difficulty: 18),
            DungeonRoom(name: "Fire Beast",          kind: .boss,        difficulty: 22),
            DungeonRoom(name: "Djinn Chamber",       kind: .djinnChamber, difficulty: 15)
        ],
        goldReward: 350
    )

    /// Phenex — Ancient Healing Temple (from the spec's acquisition example).
    static let healingTemple = Dungeon(
        id: "healing_temple",
        name: "Ancient Healing Temple",
        type: .desertCave,
        djinnReward: .phenex,
        difficulty: 2,
        rooms: [
            DungeonRoom(name: "Whispering Sands",  kind: .monster,     difficulty: 11),
            DungeonRoom(name: "Hall of Mirrors",   kind: .puzzle,      difficulty: 13),
            DungeonRoom(name: "Sand Guardian",     kind: .boss,        difficulty: 16),
            DungeonRoom(name: "Spring Chamber",    kind: .djinnChamber, difficulty: 12)
        ],
        goldReward: 220
    )

    /// Barbatos — Cavern of Strength.
    static let cavernOfStrength = Dungeon(
        id: "cavern_of_strength",
        name: "Cavern of Strength",
        type: .catacombs,
        djinnReward: .barbatos,
        difficulty: 4,
        rooms: [
            DungeonRoom(name: "Broken Stairs",     kind: .trap,        difficulty: 15),
            DungeonRoom(name: "Bone Pit",          kind: .monster,     difficulty: 17),
            DungeonRoom(name: "Riddle of Iron",    kind: .puzzle,      difficulty: 18),
            DungeonRoom(name: "Hoard Vault",       kind: .treasure,    difficulty: 14),
            DungeonRoom(name: "Stone Colossus",    kind: .boss,        difficulty: 24),
            DungeonRoom(name: "Djinn Chamber",     kind: .djinnChamber, difficulty: 16)
        ],
        goldReward: 480
    )

    /// Vinea — Sunken Galleon (shipwreck).
    static let sunkenGalleon = Dungeon(
        id: "sunken_galleon",
        name: "The Sunken Galleon",
        type: .shipwreck,
        djinnReward: .vinea,
        difficulty: 2,
        rooms: [
            DungeonRoom(name: "Flooded Deck",     kind: .trap,        difficulty: 11),
            DungeonRoom(name: "Barnacle Beasts",  kind: .monster,     difficulty: 13),
            DungeonRoom(name: "Tide Riddle",      kind: .puzzle,      difficulty: 14),
            DungeonRoom(name: "The Drowned Captain", kind: .boss,     difficulty: 17),
            DungeonRoom(name: "Coral Chamber",    kind: .djinnChamber, difficulty: 12)
        ],
        goldReward: 240
    )

    /// Paimon — Cave of Whispers (desert cave).
    static let caveOfWhispers = Dungeon(
        id: "cave_of_whispers",
        name: "Cave of Whispers",
        type: .desertCave,
        djinnReward: .paimon,
        difficulty: 2,
        rooms: [
            DungeonRoom(name: "Howling Passage",  kind: .trap,        difficulty: 12),
            DungeonRoom(name: "Dust Wraiths",     kind: .monster,     difficulty: 14),
            DungeonRoom(name: "Windward Puzzle",  kind: .puzzle,      difficulty: 13),
            DungeonRoom(name: "The Gale Warden",  kind: .boss,        difficulty: 17),
            DungeonRoom(name: "Chamber of Winds", kind: .djinnChamber, difficulty: 13)
        ],
        goldReward: 250
    )

    /// Dantalion — Tower of Dawn (wizard tower).
    static let towerOfDawn = Dungeon(
        id: "tower_of_dawn",
        name: "Tower of Dawn",
        type: .wizardTower,
        djinnReward: .dantalion,
        difficulty: 3,
        rooms: [
            DungeonRoom(name: "Mirror Foyer",      kind: .puzzle,      difficulty: 15),
            DungeonRoom(name: "Glass Sentinels",   kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Riddle of Light",   kind: .puzzle,      difficulty: 18),
            DungeonRoom(name: "Prism Vault",       kind: .treasure,    difficulty: 14),
            DungeonRoom(name: "The Blinding Seer",  kind: .boss,       difficulty: 20),
            DungeonRoom(name: "Chamber of Dawn",   kind: .djinnChamber, difficulty: 15)
        ],
        goldReward: 340
    )

    /// Zepar — Hall of Echoes (abandoned palace).
    static let hallOfEchoes = Dungeon(
        id: "hall_of_echoes",
        name: "Hall of Echoes",
        type: .abandonedPalace,
        djinnReward: .zepar,
        difficulty: 3,
        rooms: [
            DungeonRoom(name: "Whispering Foyer",  kind: .trap,        difficulty: 14),
            DungeonRoom(name: "Silent Courtiers",  kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Song of Names",     kind: .puzzle,      difficulty: 17),
            DungeonRoom(name: "The Hollow King",   kind: .boss,        difficulty: 20),
            DungeonRoom(name: "Echoing Chamber",   kind: .djinnChamber, difficulty: 14)
        ],
        goldReward: 330
    )

    /// Ugo — The Deep Foundations (catacombs).
    static let deepFoundations = Dungeon(
        id: "deep_foundations",
        name: "The Deep Foundations",
        type: .catacombs,
        djinnReward: .ugo,
        difficulty: 3,
        rooms: [
            DungeonRoom(name: "Collapsed Vault",   kind: .trap,        difficulty: 15),
            DungeonRoom(name: "Guardian Statues",  kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Keystone Puzzle",   kind: .puzzle,      difficulty: 17),
            DungeonRoom(name: "The Old Warden",    kind: .boss,        difficulty: 19),
            DungeonRoom(name: "Hearth Chamber",    kind: .djinnChamber, difficulty: 14)
        ],
        goldReward: 320,
        icon: "house.fill"          // Ugo is the Djinn of Home — its own icon
    )

    /// Baal — Storm Spire (ancient temple).
    static let stormSpire = Dungeon(
        id: "storm_spire",
        name: "Storm Spire",
        type: .ancientTemple,
        djinnReward: .baal,
        difficulty: 4,
        rooms: [
            DungeonRoom(name: "Thunder Gate",      kind: .trap,        difficulty: 16),
            DungeonRoom(name: "Charged Sentries",  kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Circuit of Bolts",  kind: .puzzle,      difficulty: 19),
            DungeonRoom(name: "Storm Vault",       kind: .treasure,    difficulty: 15),
            DungeonRoom(name: "The Sky Tyrant",    kind: .boss,        difficulty: 23),
            DungeonRoom(name: "Chamber of Storms", kind: .djinnChamber, difficulty: 16)
        ],
        goldReward: 460
    )

    /// Zagan — Garden of Renewal (ancient temple, the deadliest).
    static let gardenOfRenewal = Dungeon(
        id: "garden_of_renewal",
        name: "Garden of Renewal",
        type: .ancientTemple,
        djinnReward: .zagan,
        difficulty: 5,
        rooms: [
            DungeonRoom(name: "Thorned Threshold",  kind: .trap,        difficulty: 18),
            DungeonRoom(name: "Verdant Horrors",    kind: .monster,     difficulty: 20),
            DungeonRoom(name: "Puzzle of Seasons",  kind: .puzzle,      difficulty: 21),
            DungeonRoom(name: "Overgrown Hoard",    kind: .treasure,    difficulty: 17),
            DungeonRoom(name: "The Eternal Bloom",  kind: .monster,     difficulty: 22),
            DungeonRoom(name: "Heart of the Garden", kind: .boss,       difficulty: 26),
            DungeonRoom(name: "Chamber of Life",    kind: .djinnChamber, difficulty: 18)
        ],
        goldReward: 600
    )
}
