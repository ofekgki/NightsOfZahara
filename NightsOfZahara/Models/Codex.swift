//
//  Codex.swift
//  Nights Of Zahara
//
//  The Lore Book. Entries unlock gradually as the player progresses; locked
//  entries show only a hint of what's to come.
//

import Foundation

enum CodexCategory: String, CaseIterable, Identifiable {
    case world = "The World"
    case characters = "Characters"
    case djinns = "Djinns"
    case dungeons = "Dungeons"
    case factions = "Factions"
    var id: String { rawValue }
}

struct CodexEntry: Identifiable {
    let id: String
    let category: CodexCategory
    let title: String
    let body: String
    /// When this entry's full lore becomes readable.
    let unlock: (GameState) -> Bool
    /// When the entry's *title* becomes known (its lore may still be hidden).
    /// Defaults to the same condition as `unlock` when nil.
    var revealTitle: ((GameState) -> Bool)? = nil
}

enum Codex {
    static let entries: [CodexEntry] = worldEntries + characterEntries + djinnEntries + dungeonEntries + factionEntries

    static func unlocked(in s: GameState) -> [CodexEntry] { entries.filter { $0.unlock(s) } }
    static func entries(in category: CodexCategory) -> [CodexEntry] { entries.filter { $0.category == category } }

    // MARK: World
    static let worldEntries: [CodexEntry] = [
        CodexEntry(id: "zahara", category: .world, title: "The City of Zahara",
                   body: "Zahara is a magical desert city of markets, storytellers, sailors and hidden alleys. Ancient secrets sleep beneath its sands, and rumors of Djinn dungeons drift on every wind.",
                   unlock: { _ in true }),
        CodexEntry(id: "thousand_nights", category: .world, title: "The Thousand Nights",
                   body: "It is said a life is measured in a thousand nights. Each night a choice; each choice a thread in the tapestry of one's legend.",
                   unlock: { _ in true }),
        CodexEntry(id: "artifacts", category: .world, title: "Of Magical Artifacts",
                   body: "Each Djinn's power leaves an echo in the world — an artifact of its element, hidden in its dungeon, waiting for a worthy bearer.",
                   unlock: { ($0._meta?.artifacts.isEmpty == false) })
    ]

    // MARK: Characters
    static let characterEntries: [CodexEntry] = [
        CodexEntry(id: "scheherazade", category: .characters, title: "Scheherazade",
                   body: "The great storyteller and sorceress. She weaves protection from tales, guides seekers toward Djinn lore, and remembers every legend Zahara has ever known.",
                   unlock: { _ in true }),
        CodexEntry(id: "sinbad", category: .characters, title: "King Sinbad",
                   body: "Once a sailor who braved seven seas, now the king of Zahara. He tests the honor and courage of those who seek his favor, and rewards the worthy with royal missions.",
                   unlock: { _ in true })
    ]

    // MARK: Djinns
    // A Djinn's name is revealed once you discover its dungeon, but its full
    // story stays sealed until you conquer that dungeon and bond with it.
    static let djinnEntries: [CodexEntry] = Djinn.allCases.map { d in
        CodexEntry(id: "djinn_\(d.rawValue)", category: .djinns, title: d.name,
                   body: "\(d.domain). \(d.bonusText) Signature: \(d.abilityName) — \(d.abilityText)",
                   unlock: { $0.djinns.contains(d) },
                   revealTitle: { s in
                       s.djinns.contains(d)
                       || (DungeonCatalog.dungeon(forDjinn: d).map { s.discoveredDungeons.contains($0.id) } ?? false)
                   })
    }

    // MARK: Dungeons
    static let dungeonEntries: [CodexEntry] = DungeonCatalog.all.map { dun in
        CodexEntry(id: "dungeon_\(dun.id)", category: .dungeons, title: dun.name,
                   body: "A \(dun.type.rawValue.lowercased()) of \(dun.rooms.count) chambers, difficulty \(dun.difficultyLabel). Rumored to hold the Djinn \(dun.djinnReward?.name ?? "of legend").",
                   unlock: { $0.discoveredDungeons.contains(dun.id) })
    }

    // MARK: Factions
    static let factionEntries: [CodexEntry] = Faction.allCases.map { f in
        CodexEntry(id: "faction_\(f.rawValue)", category: .factions, title: f.title,
                   body: f.lore,
                   unlock: { _ in true })
    }
}
