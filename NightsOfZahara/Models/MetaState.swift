//
//  MetaState.swift
//  Nights Of Zahara
//
//  A single Codable container for all the "expansion" state. It is stored on
//  GameState as ONE optional property, so old saves (which lack it) still
//  decode cleanly and are back-filled with defaults on load.
//

import Foundation

// MARK: - Daily blessing / curse

struct DailyModifier: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case blessing, curse }
    var id: String
    var name: String
    var flavor: String
    var kind: Kind
    var icon: String

    // Simple numeric effects consulted by the engine.
    var luck: Int = 0
    var treasureBonus: Int = 0        // % points added to treasure rolls
    var dungeonClueBonus: Int = 0
    var energyDelta: Int = 0          // applied once at night start
    var combatBonus: Int = 0
    var shopDiscount: Int = 0         // % off shop prices
    var restBonus: Int = 0
}

// MARK: - Night summary

struct NightSummary: Codable, Identifiable {
    struct Entry: Codable, Identifiable {
        var id = UUID()
        var title: String
        var deltas: [String]
        var tone: String              // OutcomeTone raw (good/bad/neutral/epic)
    }
    var id = UUID()
    var nightNumber: Int              // the night that just ended
    var nextNight: Int
    var entries: [Entry] = []
    var goldChange: Int = 0
    var statChanges: [String] = []    // e.g. "Wisdom +3"
    var injuriesGained: Int = 0
    var events: [String] = []
    var tonightBlessing: String?      // blessing/curse for the coming night
    var newTitle: String?             // if the player's title advanced
}

// MARK: - Meta container

struct MetaState: Codable {
    // Relationships & factions (name -> level points)
    var relationships: [String: Int] = [
        "scheherazade": 0, "sinbad": 0
    ]
    var factions: [String: Int] = [:]

    // Body & fortune
    var injuries: Int = 0                 // 0 = unhurt; higher = worse
    var blessing: DailyModifier? = nil    // active for the current night

    // Wealth of materials
    var magicalDust: Int = 0
    var materials: [String: Int] = [:]    // materialID -> count

    // Items & artifacts
    var artifacts: [String] = []          // owned Djinn artifact ids
    var itemLevels: [String: Int] = [:]   // itemID -> upgrade level (0-based)
    var equipped: [String: String] = [:]  // slot rawValue -> itemID

    // Knowledge & story
    var codexUnlocked: [String] = []      // codex entry ids
    var completedMilestones: [Int] = []   // night numbers reached
    var tutorialStep: Int = 0             // Scheherazade tutorial progress
    var majorChoices: [String] = []       // ids of impactful story choices made

    // Quests, home, companions
    var acceptedQuests: [String] = []     // side/dungeon/etc quest ids in progress
    var finishedQuests: [String] = []     // completed quest ids
    var homeRooms: [String: Int] = [:]    // roomID -> level (0 = not built)
    var companions: [String] = []         // recruited companion ids

    // Last night's summary (for the popup after loading, too)
    var lastSummary: NightSummary? = nil

    // MARK: helpers
    func relationship(_ key: String) -> Int { relationships[key] ?? 0 }
    func faction(_ key: String) -> Int { factions[key] ?? 0 }

    init() {}

    // Custom decoder so new fields added over time never break old saves:
    // any missing key falls back to its default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func d<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? nil ?? fallback
        }
        relationships       = d(.relationships, ["scheherazade": 0, "sinbad": 0])
        factions            = d(.factions, [:])
        injuries            = d(.injuries, 0)
        blessing            = (try? c.decodeIfPresent(DailyModifier.self, forKey: .blessing)) ?? nil
        magicalDust         = d(.magicalDust, 0)
        materials           = d(.materials, [:])
        artifacts           = d(.artifacts, [])
        itemLevels          = d(.itemLevels, [:])
        equipped            = d(.equipped, [:])
        codexUnlocked       = d(.codexUnlocked, [])
        completedMilestones = d(.completedMilestones, [])
        tutorialStep        = d(.tutorialStep, 0)
        majorChoices        = d(.majorChoices, [])
        acceptedQuests      = d(.acceptedQuests, [])
        finishedQuests      = d(.finishedQuests, [])
        homeRooms           = d(.homeRooms, [:])
        companions          = d(.companions, [])
        lastSummary         = (try? c.decodeIfPresent(NightSummary.self, forKey: .lastSummary)) ?? nil
    }
}

// MARK: - GameState bridge

extension GameState {
    /// Non-optional, always-present accessor for the expansion state.
    /// Backed by an optional stored property so old saves decode fine.
    var meta: MetaState {
        get { _meta ?? MetaState() }
        set { _meta = newValue }
    }
}
