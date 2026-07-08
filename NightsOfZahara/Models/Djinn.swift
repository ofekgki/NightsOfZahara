//
//  Djinn.swift
//  Nights Of Zahara
//
//  The ten Djinns, their domains, bonuses and signature abilities.
//

import SwiftUI

enum Djinn: String, CaseIterable, Codable, Identifiable {
    case barbatos, phenex, vinea, dantalion, baal
    case zepar, paimon, amon, ugo, zagan

    var id: String { rawValue }

    var name: String { rawValue.capitalized }

    var domain: String {
        switch self {
        case .barbatos:  return "Djinn of Strength"
        case .phenex:    return "Djinn of Healing"
        case .vinea:     return "Djinn of Water"
        case .dantalion: return "Djinn of Light"
        case .baal:      return "Djinn of Lightning"
        case .zepar:     return "Djinn of Voice"
        case .paimon:    return "Djinn of Wind"
        case .amon:      return "Djinn of Fire"
        case .ugo:       return "Djinn of Home"
        case .zagan:     return "Djinn of Life"
        }
    }

    var icon: String {
        switch self {
        case .barbatos:  return "figure.strengthtraining.traditional"
        case .phenex:    return "cross.case"
        case .vinea:     return "drop"
        case .dantalion: return "sun.max"
        case .baal:      return "bolt"
        case .zepar:     return "waveform"
        case .paimon:    return "wind"
        case .amon:      return "flame"
        case .ugo:       return "house"
        case .zagan:     return "leaf"
        }
    }

    var color: Color {
        switch self {
        case .barbatos:  return .brown
        case .phenex:    return .pink
        case .vinea:     return .blue
        case .dantalion: return .yellow
        case .baal:      return .cyan
        case .zepar:     return .mint
        case .paimon:    return .teal
        case .amon:      return Theme.ember
        case .ugo:       return .orange
        case .zagan:     return .green
        }
    }

    var bonusText: String {
        switch self {
        case .barbatos:  return "Increased endurance & combat damage; lower injury chance."
        case .phenex:    return "Rest, food and potions heal more; injuries mend faster."
        case .vinea:     return "Safer journeys; advantage on sea and desert travel."
        case .dantalion: return "Increased wisdom; puzzles solved easier, traps revealed."
        case .baal:      return "Combat advantage; strike first, escape more easily."
        case .zepar:     return "Reputation grows faster; better connection-building."
        case .paimon:    return "Journeys go further and turn up hidden locations."
        case .amon:      return "Higher magic damage; strong advantage in dungeons."
        case .ugo:       return "Cheaper upgrades; better rest; a small nightly blessing."
        case .zagan:     return "Increased luck & endurance; more positive events."
        }
    }

    var abilityName: String {
        switch self {
        case .barbatos:  return "Barbatos' Rage"
        case .phenex:    return "Healing Flame"
        case .vinea:     return "Hidden Current"
        case .dantalion: return "Light of Truth"
        case .baal:      return "Lightning Strike"
        case .zepar:     return "Hypnotic Voice"
        case .paimon:    return "Wandering Wind"
        case .amon:      return "Amon's Flame"
        case .ugo:       return "Home Blessing"
        case .zagan:     return "Breath of Life"
        }
    }

    var abilityText: String {
        switch self {
        case .barbatos:  return "Grants a major combat advantage once every several nights."
        case .phenex:    return "Heals a serious injury or restores energy."
        case .vinea:     return "Reveals a secret route during a journey or dungeon."
        case .dantalion: return "Reveals the safest choice in a dangerous event or puzzle."
        case .baal:      return "Damages a strong enemy at the start of combat."
        case .zepar:     return "Persuades an NPC to help, or prevents combat."
        case .paimon:    return "Allows an extra journey at reduced energy cost."
        case .amon:      return "Burns an obstacle, monster or trap in a dungeon."
        case .ugo:       return "Grants a small permanent bonus each night."
        case .zagan:     return "Saves you from a severe negative outcome once a period."
        }
    }

    /// Permanent stat bonus applied when the Djinn is bonded.
    var statBonus: Stats {
        switch self {
        case .barbatos:  return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 3, cunning: 0, endurance: 6)
        case .phenex:    return Stats(wealth: 0, wisdom: 3, magic: 2, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 5)
        case .vinea:     return Stats(wealth: 0, wisdom: 0, magic: 2, reputation: 0, honor: 0, luck: 3, courage: 3, cunning: 0, endurance: 2)
        case .dantalion: return Stats(wealth: 0, wisdom: 8, magic: 3, reputation: 0, honor: 0, luck: 2, courage: 0, cunning: 0, endurance: 0)
        case .baal:      return Stats(wealth: 0, wisdom: 0, magic: 4, reputation: 0, honor: 0, luck: 0, courage: 5, cunning: 0, endurance: 0)
        case .zepar:     return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 8, honor: 3, luck: 0, courage: 0, cunning: 4, endurance: 0)
        case .paimon:    return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 5, courage: 3, cunning: 2, endurance: 0)
        case .amon:      return Stats(wealth: 0, wisdom: 0, magic: 8, reputation: 0, honor: 0, luck: 0, courage: 4, cunning: 0, endurance: 0)
        case .ugo:       return Stats(wealth: 5, wisdom: 0, magic: 0, reputation: 0, honor: 2, luck: 0, courage: 0, cunning: 0, endurance: 3)
        case .zagan:     return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 8, courage: 0, cunning: 0, endurance: 4)
        }
    }
}
