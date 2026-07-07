//
//  Faction.swift
//  Nights Of Zahara
//
//  The factions of Zahara and reputation standing with each.
//

import SwiftUI

enum Faction: String, CaseIterable, Identifiable, Codable {
    case citizens, merchants, guards, nobles, magicians, sailors, thieves, djinnSpirits

    var id: String { rawValue }

    var title: String {
        switch self {
        case .citizens:     return "Zahara Citizens"
        case .merchants:    return "Merchants' Guild"
        case .guards:       return "Palace Guards"
        case .nobles:       return "Nobles of the Court"
        case .magicians:    return "Circle of Magicians"
        case .sailors:      return "Sailors of the Port"
        case .thieves:      return "Thieves' Guild"
        case .djinnSpirits: return "Djinn Spirits"
        }
    }

    var icon: String {
        switch self {
        case .citizens:     return "person.3.fill"
        case .merchants:    return "cart.fill"
        case .guards:       return "shield.righthalf.filled"
        case .nobles:       return "crown.fill"
        case .magicians:    return "wand.and.stars"
        case .sailors:      return "sailboat.fill"
        case .thieves:      return "eye.fill"
        case .djinnSpirits: return "sparkles"
        }
    }

    var lore: String {
        switch self {
        case .citizens:     return "The common folk of Zahara — shopkeepers, water-sellers and street children. Their goodwill spreads your name through the markets."
        case .merchants:    return "The traders who control the flow of goods. Their favor means better prices and rare wares."
        case .guards:       return "Sinbad's palace guard. Their trust eases your passage into the palace."
        case .nobles:       return "The courtiers who orbit the king. Their approval opens political doors."
        case .magicians:    return "Keepers of arcane knowledge and Djinn lore. Their guidance sharpens your search for dungeons."
        case .sailors:      return "Weathered travelers of the port. They know the sea roads and share tales of distant treasure."
        case .thieves:      return "A shadowy guild of cutpurses and spies. Their whispers reveal what nobles would hide."
        case .djinnSpirits: return "The elemental spirits bound to ancient dungeons. Only the bonded earn their respect."
        }
    }

    /// A human-readable standing label for a reputation value.
    static func standing(_ value: Int) -> String {
        switch value {
        case ..<0:   return "Hostile"
        case 0..<10: return "Neutral"
        case 10..<25: return "Friendly"
        case 25..<50: return "Honored"
        case 50..<80: return "Revered"
        default:     return "Exalted"
        }
    }

    static func standingColor(_ value: Int) -> Color {
        switch value {
        case ..<0:    return Theme.danger
        case 0..<10:  return Theme.sand
        case 10..<25: return .green
        case 25..<50: return .cyan
        default:      return Theme.brightGold
        }
    }
}
