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
    // Themed homes for the additional Djinns.
    case nightmareHollow  = "Nightmare Hollow"
    case shiftingPassage  = "Shifting Passage"
    case battlefieldAshes = "Ashen Battlefield"
    case silentShrine     = "Silent Shrine"
    case thunderSpire     = "Thunder Spire"
    case glassRoses       = "Glass-Rose Palace"
    case laughingStars    = "Star Garden"
    case endlessVault     = "Merchant Vault"
    case falseDoors       = "False Labyrinth"
    case brokenOaths      = "Hall of Oaths"
    case cycloneRuins     = "Cyclone Ruins"
    case sandCourt        = "Sunken Court"
    case hiddenFlame      = "Throne of Flame"

    var icon: String {
        switch self {
        case .desertCave:      return "mountain.2"
        case .ancientTemple:   return "building.columns"
        case .shipwreck:       return "ferry"
        case .wizardTower:     return "building"
        case .catacombs:       return "skull"
        case .abandonedPalace: return "crown"
        case .nightmareHollow:  return "theatermasks.fill"
        case .shiftingPassage:  return "arrow.triangle.branch"
        case .battlefieldAshes: return "flame.circle.fill"
        case .silentShrine:     return "hand.raised.fill"
        case .thunderSpire:     return "bolt.circle.fill"
        case .glassRoses:       return "sparkles"
        case .laughingStars:    return "sparkle"
        case .endlessVault:     return "banknote.fill"
        case .falseDoors:       return "door.left.hand.closed"
        case .brokenOaths:      return "scroll.fill"
        case .cycloneRuins:     return "tornado"
        case .sandCourt:        return "scalemass.fill"
        case .hiddenFlame:      return "flame.fill"
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

    /// Recommended minimum for a tested stat, scaled by difficulty. Dungeons
    /// above Hard (difficulty > 3) demand notably higher stats.
    var requirementTarget: Int {
        let base = 10 + difficulty * 6
        return difficulty > 3 ? base + (difficulty - 3) * 8 : base
    }

    /// A recommended minimum for each tested stat. Endurance is listed
    /// separately via `recommendedEndurance`, so it is not repeated here.
    var recommendedStats: [(StatKind, Int)] {
        testedStats.filter { $0 != .endurance }.map { ($0, requirementTarget) }
    }

    /// Recommended endurance to survive the crawl.
    var recommendedEndurance: Int {
        let base = 12 + difficulty * 7
        return difficulty > 3 ? base + (difficulty - 3) * 8 : base
    }

    /// Energy cost to enter. The King's throne (difficulty 6) costs far more.
    var entryEnergyCost: Int { difficulty >= 6 ? 12 : 4 }

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

    /// All discoverable dungeons — one per collectible Djinn. (Al-Mudhib's
    /// Throne of the Hidden Flame is a separate, gated endgame dungeon and is
    /// intentionally not listed here — see KingOfDjinns.swift.)
    static let all: [Dungeon] = [
        healingTemple, sunkenGalleon, caveOfWhispers,     // difficulty 2
        templeOfFire, towerOfDawn, hallOfEchoes, deepFoundations, // difficulty 3
        cavernOfStrength, stormSpire,                     // difficulty 4
        gardenOfRenewal,                                  // difficulty 5
        // Additional Djinn dungeons.
        shiftingPassage, silentShrine, palaceGlassRoses, gardenLaughingStars, // difficulty 3
        nightmareHollow, thunderSpire, vaultBargains, labyrinthFalseDoors, hallBrokenOaths, // difficulty 4
        battlefieldAshes, cycloneRuins, courtBeneathSand  // difficulty 5
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

    // MARK: - Additional Djinn dungeons

    /// Nasnas — The Shifting Passage (difficulty 3).
    static let shiftingPassage = Dungeon(
        id: "shifting_passage", name: "The Shifting Passage", type: .shiftingPassage,
        djinnReward: .nasnas, difficulty: 3,
        rooms: [
            DungeonRoom(name: "Moving Walls",      kind: .trap,        difficulty: 15),
            DungeonRoom(name: "Speed Trial",       kind: .puzzle,      difficulty: 16),
            DungeonRoom(name: "Swift Stalkers",    kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Blade Corridor",    kind: .trap,        difficulty: 17),
            DungeonRoom(name: "The Blur",          kind: .boss,        difficulty: 20),
            DungeonRoom(name: "Chamber of Haste",  kind: .djinnChamber, difficulty: 14)
        ], goldReward: 330)

    /// Khanzan — The Silent Shrine (difficulty 3).
    static let silentShrine = Dungeon(
        id: "silent_shrine", name: "The Silent Shrine", type: .silentShrine,
        djinnReward: .khanzan, difficulty: 3,
        rooms: [
            DungeonRoom(name: "Cursed Prayers",    kind: .trap,        difficulty: 15),
            DungeonRoom(name: "Spirit Guardians",  kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Room of Judgment",  kind: .puzzle,      difficulty: 17),
            DungeonRoom(name: "The Corrupted Priest", kind: .boss,     difficulty: 20),
            DungeonRoom(name: "Chamber of Faith",  kind: .djinnChamber, difficulty: 14)
        ], goldReward: 320)

    /// Maymunah — The Palace of Glass Roses (difficulty 3).
    static let palaceGlassRoses = Dungeon(
        id: "palace_glass_roses", name: "The Palace of Glass Roses", type: .glassRoses,
        djinnReward: .maymunah, difficulty: 3,
        rooms: [
            DungeonRoom(name: "Enchanted Statues", kind: .monster,     difficulty: 15),
            DungeonRoom(name: "Charm Illusions",   kind: .puzzle,      difficulty: 17),
            DungeonRoom(name: "Mirror Garden",     kind: .trap,        difficulty: 16),
            DungeonRoom(name: "Jealous Spirits",   kind: .monster,     difficulty: 17),
            DungeonRoom(name: "The Graceful Guardian", kind: .boss,    difficulty: 20),
            DungeonRoom(name: "Chamber of Roses",  kind: .djinnChamber, difficulty: 14)
        ], goldReward: 340)

    /// Danhash — The Garden of Laughing Stars (difficulty 3).
    static let gardenLaughingStars = Dungeon(
        id: "garden_laughing_stars", name: "The Garden of Laughing Stars", type: .laughingStars,
        djinnReward: .danhash, difficulty: 3,
        rooms: [
            DungeonRoom(name: "Glowing Flowers",   kind: .trap,        difficulty: 14),
            DungeonRoom(name: "Joy Spirits",       kind: .monster,     difficulty: 16),
            DungeonRoom(name: "Emotional Trial",   kind: .puzzle,      difficulty: 17),
            DungeonRoom(name: "Dreamlike Riddle",  kind: .puzzle,      difficulty: 16),
            DungeonRoom(name: "The Sorrowful Guardian", kind: .boss,   difficulty: 20),
            DungeonRoom(name: "Chamber of Joy",    kind: .djinnChamber, difficulty: 14)
        ], goldReward: 330)

    /// Shiqq — The Nightmare Hollow (difficulty 4).
    static let nightmareHollow = Dungeon(
        id: "nightmare_hollow", name: "The Nightmare Hollow", type: .nightmareHollow,
        djinnReward: .shiqq, difficulty: 4,
        rooms: [
            DungeonRoom(name: "Whispering Walls",  kind: .trap,        difficulty: 17),
            DungeonRoom(name: "Shadow Beasts",     kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Cursed Mirrors",    kind: .puzzle,      difficulty: 18),
            DungeonRoom(name: "Fear Traps",        kind: .trap,        difficulty: 19),
            DungeonRoom(name: "The Nightmare Guardian", kind: .boss,   difficulty: 23),
            DungeonRoom(name: "Chamber of Dread",  kind: .djinnChamber, difficulty: 16)
        ], goldReward: 460)

    /// Barqan — The Thunder Spire (difficulty 4).
    static let thunderSpire = Dungeon(
        id: "thunder_spire_barqan", name: "The Thunder Spire", type: .thunderSpire,
        djinnReward: .barqan, difficulty: 4,
        rooms: [
            DungeonRoom(name: "Lightning Crystals", kind: .trap,       difficulty: 17),
            DungeonRoom(name: "Storm Spirits",     kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Floating Platforms", kind: .puzzle,     difficulty: 18),
            DungeonRoom(name: "Electric Vault",    kind: .treasure,    difficulty: 15),
            DungeonRoom(name: "The Thunder Beast", kind: .boss,        difficulty: 23),
            DungeonRoom(name: "Chamber of Bolts",  kind: .djinnChamber, difficulty: 16)
        ], goldReward: 470)

    /// Zalmbur — The Vault of Endless Bargains (difficulty 4).
    static let vaultBargains = Dungeon(
        id: "vault_bargains", name: "The Vault of Endless Bargains", type: .endlessVault,
        djinnReward: .zalmbur, difficulty: 4,
        rooms: [
            DungeonRoom(name: "Cursed Coins",      kind: .trap,        difficulty: 17),
            DungeonRoom(name: "Greedy Spirits",    kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Negotiation Trial", kind: .puzzle,      difficulty: 18),
            DungeonRoom(name: "Treasure Hoard",    kind: .treasure,    difficulty: 15),
            DungeonRoom(name: "The Coin Golem",    kind: .boss,        difficulty: 22),
            DungeonRoom(name: "Chamber of Gold",   kind: .djinnChamber, difficulty: 16)
        ], goldReward: 500)

    /// Sut — The Labyrinth of False Doors (difficulty 4).
    static let labyrinthFalseDoors = Dungeon(
        id: "labyrinth_false_doors", name: "The Labyrinth of False Doors", type: .falseDoors,
        djinnReward: .sut, difficulty: 4,
        rooms: [
            DungeonRoom(name: "Fake Exits",        kind: .trap,        difficulty: 18),
            DungeonRoom(name: "Illusion Monsters", kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Lying Statues",     kind: .puzzle,      difficulty: 19),
            DungeonRoom(name: "False Treasure Room", kind: .treasure,  difficulty: 16),
            DungeonRoom(name: "The Shapeshifter",  kind: .boss,        difficulty: 23),
            DungeonRoom(name: "Chamber of Masks",  kind: .djinnChamber, difficulty: 16)
        ], goldReward: 460)

    /// Dasim — The Hall of Broken Oaths (difficulty 4).
    static let hallBrokenOaths = Dungeon(
        id: "hall_broken_oaths", name: "The Hall of Broken Oaths", type: .brokenOaths,
        djinnReward: .dasim, difficulty: 4,
        rooms: [
            DungeonRoom(name: "Arguing Spirits",   kind: .monster,     difficulty: 18),
            DungeonRoom(name: "Betrayal Traps",    kind: .trap,        difficulty: 18),
            DungeonRoom(name: "Cursed Contracts",  kind: .puzzle,      difficulty: 19),
            DungeonRoom(name: "Rival Guardians",   kind: .monster,     difficulty: 19),
            DungeonRoom(name: "The Duelist",       kind: .boss,        difficulty: 23),
            DungeonRoom(name: "Chamber of Oaths",  kind: .djinnChamber, difficulty: 16)
        ], goldReward: 470)

    /// Ifrit — The Battlefield of Ashes (difficulty 5).
    static let battlefieldAshes = Dungeon(
        id: "battlefield_ashes", name: "The Battlefield of Ashes", type: .battlefieldAshes,
        djinnReward: .ifrit, difficulty: 5,
        rooms: [
            DungeonRoom(name: "Broken Weapons",    kind: .trap,        difficulty: 19),
            DungeonRoom(name: "Cursed Soldiers",   kind: .monster,     difficulty: 21),
            DungeonRoom(name: "Fire Traps",        kind: .trap,        difficulty: 20),
            DungeonRoom(name: "Siege Beasts",      kind: .monster,     difficulty: 22),
            DungeonRoom(name: "The Warlord",       kind: .boss,        difficulty: 26),
            DungeonRoom(name: "Chamber of War",    kind: .djinnChamber, difficulty: 18)
        ], goldReward: 600)

    /// Zawba'ah — The Cyclone Ruins (difficulty 5).
    static let cycloneRuins = Dungeon(
        id: "cyclone_ruins", name: "The Cyclone Ruins", type: .cycloneRuins,
        djinnReward: .zawbaah, difficulty: 5,
        rooms: [
            DungeonRoom(name: "Wind Tunnels",      kind: .trap,        difficulty: 19),
            DungeonRoom(name: "Sand Beasts",       kind: .monster,     difficulty: 21),
            DungeonRoom(name: "Storm Puzzle",      kind: .puzzle,      difficulty: 21),
            DungeonRoom(name: "Flying Horrors",    kind: .monster,     difficulty: 22),
            DungeonRoom(name: "The Cyclone Guardian", kind: .boss,     difficulty: 26),
            DungeonRoom(name: "Chamber of Winds",  kind: .djinnChamber, difficulty: 18)
        ], goldReward: 600)

    /// Shamhurish — The Court Beneath the Sand (difficulty 5).
    static let courtBeneathSand = Dungeon(
        id: "court_beneath_sand", name: "The Court Beneath the Sand", type: .sandCourt,
        djinnReward: .shamhurish, difficulty: 5,
        rooms: [
            DungeonRoom(name: "Judgment Statues",  kind: .monster,     difficulty: 20),
            DungeonRoom(name: "Truth Trial",       kind: .puzzle,      difficulty: 21),
            DungeonRoom(name: "Law Spirits",       kind: .monster,     difficulty: 22),
            DungeonRoom(name: "Moral Puzzle",      kind: .puzzle,      difficulty: 21),
            DungeonRoom(name: "The Final Judge",   kind: .boss,        difficulty: 26),
            DungeonRoom(name: "Chamber of Law",    kind: .djinnChamber, difficulty: 18)
        ], goldReward: 620)
}
