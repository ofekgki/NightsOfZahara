//
//  Role.swift
//  Nights Of Zahara
//
//  The five starting roles, their bonuses, weaknesses and flavour.
//

import SwiftUI

enum Role: String, CaseIterable, Codable, Identifiable {
    case marketOrphan   = "Market Orphan"
    case wizardApprentice = "Wizard Apprentice"
    case merchant       = "Merchant"
    case sailor         = "Sailor"
    case storyteller    = "Storyteller"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .marketOrphan:    return "figure.walk"
        case .wizardApprentice: return "wand.and.stars"
        case .merchant:        return "cart"
        case .sailor:          return "sailboat"
        case .storyteller:     return "text.book.closed"
        }
    }

    var tagline: String {
        switch self {
        case .marketOrphan:    return "Street-raised, quick and lucky"
        case .wizardApprentice: return "Young student of the arcane arts"
        case .merchant:        return "Trader of goods and secrets"
        case .sailor:          return "Weathered traveler of the seas"
        case .storyteller:     return "Charismatic voice of the tea houses"
        }
    }

    var description: String {
        switch self {
        case .marketOrphan:
            return "A poor, street-raised soul who grew up surviving in Zahara's markets. Cunning and lucky, quick to escape danger, but low on wealth and honor."
        case .wizardApprentice:
            return "A young apprentice who studied under an old magician. Strong in magic and wisdom, able to sense magical dungeons early, but frail in body."
        case .merchant:
            return "A trader who understands negotiation and opportunity. Wealthy and well-regarded, earns more from trade, but weak in combat and dependent on gold."
        case .sailor:
            return "A traveler of storms, islands and long journeys. Tough and brave, excellent on journeys, but with little magic and less palace influence."
        case .storyteller:
            return "A charismatic speaker of the tea houses and royal courts. Renowned and wise, able to sway people and open palace doors, but poor in a fight."
        }
    }

    var playstyle: String {
        switch self {
        case .marketOrphan:    return "Risky, flexible, treasure-hunting"
        case .wizardApprentice: return "Magic, Djinns and puzzles"
        case .merchant:        return "Economy and connections"
        case .sailor:          return "Journeys and adventure"
        case .storyteller:     return "Social, palace and influence"
        }
    }

    var strengths: [String] {
        switch self {
        case .marketOrphan:    return ["High cunning & luck", "Finds small treasures", "Escapes danger easily"]
        case .wizardApprentice: return ["High magic & wisdom", "Early spell learning", "Senses magical dungeons"]
        case .merchant:        return ["High starting wealth", "Good reputation", "Earns more from trade"]
        case .sailor:          return ["High endurance & courage", "Great on journeys", "Finds sea treasures"]
        case .storyteller:     return ["High reputation & wisdom", "Influences people", "Opens palace doors"]
        }
    }

    var weaknesses: [String] {
        switch self {
        case .marketOrphan:    return ["Low wealth & honor", "Hard to enter the palace early"]
        case .wizardApprentice: return ["Low endurance", "Weak early combat"]
        case .merchant:        return ["Weak in combat", "Attracts thieves"]
        case .sailor:          return ["Low palace influence", "Low magic"]
        case .storyteller:     return ["Weak in combat", "Poor at hard labor"]
        }
    }

    /// Stat bonuses added on top of `Stats.baseline`.
    var bonuses: Stats {
        switch self {
        case .marketOrphan:
            return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0,
                         luck: 8, courage: 5, cunning: 10, endurance: 0)
        case .wizardApprentice:
            return Stats(wealth: 0, wisdom: 10, magic: 12, reputation: 0, honor: 0,
                         luck: 3, courage: 0, cunning: 0, endurance: -3)
        case .merchant:
            return Stats(wealth: 15, wisdom: 0, magic: 0, reputation: 8, honor: 5,
                         luck: 0, courage: 0, cunning: 4, endurance: 0)
        case .sailor:
            return Stats(wealth: 0, wisdom: 0, magic: -3, reputation: 0, honor: 0,
                         luck: 5, courage: 10, cunning: 0, endurance: 12)
        case .storyteller:
            return Stats(wealth: 0, wisdom: 8, magic: 0, reputation: 12, honor: 5,
                         luck: 0, courage: 0, cunning: 5, endurance: 0)
        }
    }

    /// Extra starting gold on top of the base purse.
    var startingGold: Int {
        switch self {
        case .marketOrphan:    return 20
        case .wizardApprentice: return 40
        case .merchant:        return 150
        case .sailor:          return 60
        case .storyteller:     return 70
        }
    }
}
