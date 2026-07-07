//
//  Monster.swift
//  Nights Of Zahara
//
//  Detailed monster data shown on monster/boss rooms during a dungeon crawl.
//  Monsters are generated procedurally from the room, dungeon and night so
//  they scale with difficulty.
//

import Foundation

/// A tiny deterministic RNG so a room always yields the same monster.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

struct Monster: Identifiable {
    let id = UUID()
    var name: String
    var level: Int
    var health: Int
    var attack: Int
    var defense: Int
    var magic: Int
    var speed: Int
    var special: String
    var weakness: String
    var reward: String
}

enum MonsterFactory {
    private static let names: [DungeonType: [String]] = [
        .ancientTemple:   ["Fire Guardian", "Temple Sentinel", "Ashen Revenant", "Flame Beast"],
        .desertCave:      ["Sand Wraith", "Dust Stalker", "Cave Lurker", "Gale Warden"],
        .shipwreck:       ["Barnacle Beast", "Drowned Sailor", "Coral Horror", "The Drowned Captain"],
        .wizardTower:     ["Glass Sentinel", "Mirror Shade", "Arcane Construct", "The Blinding Seer"],
        .catacombs:       ["Bone Stalker", "Crypt Guardian", "Stone Colossus", "The Old Warden"],
        .abandonedPalace: ["Silent Courtier", "Hollow Noble", "Echo Phantom", "The Hollow King"]
    ]

    private static let specials = [
        "Drains player energy", "Strikes twice before you can react", "Shrugs off magic",
        "Enrages when wounded", "Curses your next action", "Summons lesser spirits"
    ]
    private static let weaknesses = ["Fire", "Water", "Light", "Lightning", "Cunning", "Courage"]

    static func make(for room: DungeonRoom, in dungeon: Dungeon, night: Int) -> Monster {
        let isBoss = room.kind == .boss
        // Difficulty scales with the dungeon and, gently, with the night number.
        let nightScale = 1.0 + Double(night) / 1400.0
        let base = Double(room.difficulty) * nightScale
        let lvl = max(1, Int(base) + dungeon.difficulty * 2 + (isBoss ? 6 : 0))

        // Seed from the room so the same room always yields the same monster.
        var rng = SeededGenerator(seed: UInt64(abs(room.id.hashValue & 0x7FFFFFFF)) &+ UInt64(dungeon.difficulty))
        let pool = names[dungeon.type] ?? ["Desert Horror"]
        let name = isBoss ? (pool.last ?? "Dungeon Boss")
                          : (pool.dropLast().randomElement(using: &rng) ?? room.name)

        return Monster(
            name: name,
            level: lvl,
            health: Int(base * (isBoss ? 8 : 4)),
            attack: Int(base * (isBoss ? 1.4 : 1.0)),
            defense: Int(base * 0.6) + dungeon.difficulty,
            magic: Int(base * (isBoss ? 1.2 : 0.8)),
            speed: Int(base * 0.5) + 4,
            special: specials.randomElement(using: &rng) ?? "Unknown power",
            weakness: weaknesses.randomElement(using: &rng) ?? "Unknown",
            reward: isBoss ? "Gold, gear, and passage to the Djinn chamber"
                           : "Gold, and a chance of shadow dust"
        )
    }
}
