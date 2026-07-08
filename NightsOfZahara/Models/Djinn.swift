//
//  Djinn.swift
//  Nights Of Zahara
//
//  The Djinns of Zahara — their domains, bonuses and signature abilities.
//  The original ten remain unchanged; twelve more Djinns join the roster.
//  (Al-Mudhib, King of the Djinns, is a separate legendary figure — see
//  KingOfDjinns.swift — and is deliberately NOT part of this collection.)
//

import SwiftUI

enum Djinn: String, CaseIterable, Codable, Identifiable {
    // Original ten.
    case barbatos, phenex, vinea, dantalion, baal
    case zepar, paimon, amon, ugo, zagan
    // Twelve additional Djinns.
    case shiqq, nasnas, ifrit, khanzan, barqan, maymunah
    case danhash, zalmbur, sut, dasim, zawbaah, shamhurish

    var id: String { rawValue }

    var name: String {
        switch self {
        case .zawbaah: return "Zawba'ah"
        default:       return rawValue.capitalized
        }
    }

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
        case .shiqq:     return "Djinn of Fear"
        case .nasnas:    return "Djinn of Speed"
        case .ifrit:     return "Djinn of War"
        case .khanzan:   return "Djinn of Prayer"
        case .barqan:    return "Djinn of Lightning"
        case .maymunah:  return "Djinn of Beauty"
        case .danhash:   return "Djinn of Happiness"
        case .zalmbur:   return "Djinn of Merchants"
        case .sut:       return "Djinn of Lies"
        case .dasim:     return "Djinn of Conflict"
        case .zawbaah:   return "Djinn of Storms"
        case .shamhurish:return "Djinn of Judgment"
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
        case .shiqq:     return "theatermasks.fill"
        case .nasnas:    return "hare.fill"
        case .ifrit:     return "flame.circle.fill"
        case .khanzan:   return "hand.raised.fill"
        case .barqan:    return "bolt.circle.fill"
        case .maymunah:  return "sparkles"
        case .danhash:   return "face.smiling.fill"
        case .zalmbur:   return "banknote.fill"
        case .sut:       return "eye.slash.fill"
        case .dasim:     return "bolt.horizontal.fill"
        case .zawbaah:   return "tornado"
        case .shamhurish:return "scalemass.fill"
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
        case .shiqq:     return .indigo
        case .nasnas:    return .mint
        case .ifrit:     return Theme.danger
        case .khanzan:   return .yellow
        case .barqan:    return .blue
        case .maymunah:  return .pink
        case .danhash:   return .yellow
        case .zalmbur:   return Theme.gold
        case .sut:       return .purple
        case .dasim:     return .orange
        case .zawbaah:   return .teal
        case .shamhurish:return Theme.brightGold
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
        case .shiqq:     return "Intimidation succeeds more; fear-based foes fear you; may scare enemies off."
        case .nasnas:    return "Greatly increased Speed; strike first, escape more, swifter journeys."
        case .ifrit:     return "Increased combat power & courage; bonus damage to dungeon bosses."
        case .khanzan:   return "Resists curses, fear and illusions; steadier wisdom-based choices."
        case .barqan:    return "Increased Speed & Magic; lightning damage and first strikes in combat."
        case .maymunah:  return "Reputation & honor grow faster; stronger palace and social outcomes."
        case .danhash:   return "Increased Luck; more positive events; happier companions."
        case .zalmbur:   return "More gold from work; better shop prices and merchant favor."
        case .sut:       return "Increased Cunning; deception and stealth succeed; sees through false clues."
        case .dasim:     return "Improved intimidation; advantage against hostile NPCs and rivals."
        case .zawbaah:   return "Survives storms; better journeys in harsh weather; reveals desert secrets."
        case .shamhurish:return "Increased Honor & wisdom; advantage in palace trials and Sinbad's court."
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
        case .shiqq:     return "Terror Gaze"
        case .nasnas:    return "Blink Step"
        case .ifrit:     return "Warflame Command"
        case .khanzan:   return "Sacred Focus"
        case .barqan:    return "Thunder Strike"
        case .maymunah:  return "Radiant Charm"
        case .danhash:   return "Joyful Omen"
        case .zalmbur:   return "Golden Bargain"
        case .sut:       return "False Mask"
        case .dasim:     return "Spark of Discord"
        case .zawbaah:   return "Eye of the Storm"
        case .shamhurish:return "Verdict of Truth"
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
        case .paimon:    return "Allows an extra journey and finds hidden places."
        case .amon:      return "Burns an obstacle, monster or trap in a dungeon."
        case .ugo:       return "Grants a small permanent bonus each night."
        case .zagan:     return "Saves you from a severe negative outcome once a period."
        case .shiqq:     return "Weakens every enemy in a dungeon room — lowering attack, courage and accuracy."
        case .nasnas:    return "Dodges one enemy attack, trap or failed escape entirely."
        case .ifrit:     return "Greatly increases your damage for one major fight or dungeon room."
        case .khanzan:   return "Cancels one curse, fear effect or spiritual trap."
        case .barqan:    return "Strikes one enemy with lightning at the start of combat and may stun it."
        case .maymunah:  return "Turns one social failure into success, or softens a palace event."
        case .danhash:   return "Turns one neutral or negative event into a better outcome."
        case .zalmbur:   return "Slashes the price of a shop item, or boosts a work/trade reward."
        case .sut:       return "Escapes one failed social, stealth or deception attempt without penalty."
        case .dasim:     return "Turns enemies or rivals against each other, easing one room or event."
        case .zawbaah:   return "Cancels or weakens a storm or journey hazard, and may reveal a hidden place."
        case .shamhurish:return "Reveals the most honorable, truthful choice in a trial or major event."
        }
    }

    /// Permanent stat bonus applied when the Djinn is bonded. (Wealth is
    /// deliberately avoided — it is derived from the player's gold.)
    var statBonus: Stats {
        switch self {
        case .barbatos:  return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 0, courage: 3, cunning: 0, endurance: 6)
        case .phenex:    return Stats(wealth: 0, wisdom: 3, magic: 2, reputation: 0, honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 5)
        case .vinea:     return Stats(wealth: 0, wisdom: 0, magic: 2, reputation: 0, honor: 0, luck: 3, courage: 3, cunning: 0, endurance: 2)
        case .dantalion: return Stats(wealth: 0, wisdom: 8, magic: 3, reputation: 0, honor: 0, luck: 2, courage: 0, cunning: 0, endurance: 0)
        case .baal:      return Stats(wealth: 0, wisdom: 0, magic: 4, reputation: 0, honor: 0, luck: 0, courage: 5, cunning: 0, endurance: 0)
        case .zepar:     return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 8, honor: 3, luck: 0, courage: 0, cunning: 4, endurance: 0)
        case .paimon:    return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 5, courage: 3, cunning: 2, endurance: 0, speed: 3)
        case .amon:      return Stats(wealth: 0, wisdom: 0, magic: 8, reputation: 0, honor: 0, luck: 0, courage: 4, cunning: 0, endurance: 0)
        case .ugo:       return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 2, luck: 0, courage: 0, cunning: 0, endurance: 3)
        case .zagan:     return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 8, courage: 0, cunning: 0, endurance: 4)
        case .shiqq:     return Stats(wealth: 0, wisdom: 0, magic: 2, reputation: 0, honor: 0, luck: 0, courage: 5, cunning: 4, endurance: 0)
        case .nasnas:    return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 3, courage: 2, cunning: 0, endurance: 0, speed: 9)
        case .ifrit:     return Stats(wealth: 0, wisdom: 0, magic: 2, reputation: 0, honor: 0, luck: 0, courage: 9, cunning: 0, endurance: 3)
        case .khanzan:   return Stats(wealth: 0, wisdom: 6, magic: 3, reputation: 0, honor: 4, luck: 0, courage: 0, cunning: 0, endurance: 2)
        case .barqan:    return Stats(wealth: 0, wisdom: 0, magic: 6, reputation: 0, honor: 0, luck: 0, courage: 2, cunning: 0, endurance: 0, speed: 5)
        case .maymunah:  return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 9, honor: 4, luck: 0, courage: 0, cunning: 2, endurance: 0)
        case .danhash:   return Stats(wealth: 0, wisdom: 2, magic: 0, reputation: 2, honor: 0, luck: 9, courage: 0, cunning: 0, endurance: 0)
        case .zalmbur:   return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 4, honor: 0, luck: 2, courage: 0, cunning: 5, endurance: 0)
        case .sut:       return Stats(wealth: 0, wisdom: 0, magic: 2, reputation: 0, honor: 0, luck: 3, courage: 0, cunning: 9, endurance: 0)
        case .dasim:     return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 2, honor: 0, luck: 0, courage: 4, cunning: 5, endurance: 0)
        case .zawbaah:   return Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0, honor: 0, luck: 3, courage: 2, cunning: 0, endurance: 5, speed: 4)
        case .shamhurish:return Stats(wealth: 0, wisdom: 5, magic: 0, reputation: 2, honor: 9, luck: 0, courage: 0, cunning: 0, endurance: 0)
        }
    }
}
