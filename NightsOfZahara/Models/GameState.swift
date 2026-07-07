//
//  GameState.swift
//  Nights Of Zahara
//
//  The complete, Codable snapshot of a playthrough. This is what gets
//  saved to and loaded from disk.
//

import Foundation

struct GameState: Codable {
    // Identity
    var characterName: String
    var role: Role

    // Progression
    var night: Int = 1
    var energy: Int = 6
    var maxEnergy: Int = 6
    var gold: Int

    // Character
    var stats: Stats

    // Collections
    var djinns: [Djinn] = []
    var inventory: [String: Int] = [:]          // itemID : count
    var discoveredDungeons: [String] = []        // dungeon ids known
    var completedDungeons: [String] = []         // dungeon ids conquered
    var connections: [String] = []               // named allies
    var treasuresFound: Int = 0

    // Flags
    var palaceUnlocked: Bool = false
    var pendingDungeonClues: Int = 0             // clues that boost the next search

    // Palace / royal missions
    var activeQuestID: String? = nil
    var completedQuestIDs: [String] = []

    // Journal — recent story lines shown in the city
    var journal: [String] = []

    static let totalNights = 1000

    // MARK: - Derived

    var isFinished: Bool { night > GameState.totalNights }

    /// Max energy scales as the legend grows (spec: 6 → 8 → 10+).
    var energyForCurrentEra: Int {
        switch night {
        case ...200:  return 6
        case ...500:  return 8
        case ...800:  return 9
        default:      return 10
        }
    }

    var era: String {
        switch night {
        case ...50:   return "Introduction"
        case ...200:  return "Development"
        case ...500:  return "Adventure"
        case ...800:  return "Power"
        default:      return "Legend"
        }
    }

    // MARK: - Factory

    static func new(name: String, role: Role) -> GameState {
        let stats = Stats.baseline + role.bonuses
        return GameState(
            characterName: name.isEmpty ? "Wanderer" : name,
            role: role,
            night: 1,
            energy: 6,
            maxEnergy: 6,
            gold: 50 + role.startingGold,
            stats: stats,
            journal: ["Scheherazade greets you in Zahara. \"Your first of a thousand nights begins...\""]
        )
    }
}
