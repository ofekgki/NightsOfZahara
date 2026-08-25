//  The recurring major characters of Zahara — Ali Baba, Jasmine and Aladdin —
//  each with a relationship that deepens through tiers and unlocks quests,
//  bonuses, companionship and even endings. (Scheherazade and King Sinbad are
//  handled separately as the framing narrators.)

import SwiftUI

/// The bond tiers a major character relationship passes through.
enum CharacterTier: Int, Comparable {
    case stranger = 0, friendly, trusted, loyal, legendary

    /// Map a relationship point total to a tier.
    static func from(_ value: Int) -> CharacterTier {
        switch value {
        case ..<10:  return .stranger
        case ..<25:  return .friendly
        case ..<50:  return .trusted
        case ..<80:  return .loyal
        default:     return .legendary
        }
    }

    var title: String {
        switch self {
        case .stranger:  return "Unmet"
        case .friendly:  return "Friendly"
        case .trusted:   return "Trusted"
        case .loyal:     return "Loyal"
        case .legendary: return "Legendary Bond"
        }
    }

    var color: Color {
        switch self {
        case .stranger:  return Theme.sand
        case .friendly:  return .green
        case .trusted:   return .cyan
        case .loyal:     return Theme.brightGold
        case .legendary: return Theme.ember
        }
    }

    /// Point total at which the next tier begins (nil once Legendary).
    var nextThreshold: Int? {
        switch self {
        case .stranger:  return 10
        case .friendly:  return 25
        case .trusted:   return 50
        case .loyal:     return 80
        case .legendary: return nil
        }
    }

    static func < (a: CharacterTier, b: CharacterTier) -> Bool { a.rawValue < b.rawValue }
}

enum MajorCharacter: String, CaseIterable, Identifiable {
    case aliBaba = "alibaba"
    case jasmine = "jasmine"
    case aladdin = "aladdin"

    var id: String { rawValue }
    /// Key used in `MetaState.relationships`.
    var relationshipKey: String { rawValue }

    var name: String {
        switch self {
        case .aliBaba: return "Ali Baba"
        case .jasmine: return "Jasmine"
        case .aladdin: return "Aladdin"
        }
    }

    var role: String {
        switch self {
        case .aliBaba: return "Treasure Hunter & Cave Expert"
        case .jasmine: return "Noble Diplomat & Voice of the People"
        case .aladdin: return "Street-Smart Artifact Seeker"
        }
    }

    var icon: String {
        switch self {
        case .aliBaba: return "key.fill"
        case .jasmine: return "hands.and.sparkles.fill"
        case .aladdin: return "lamp.table.fill"
        }
    }

    var color: Color {
        switch self {
        case .aliBaba: return Theme.gold
        case .jasmine: return .pink
        case .aladdin: return .purple
        }
    }

    /// Full Codex lore (revealed once the bond reaches Trusted).
    var codexBody: String {
        switch self {
        case .aliBaba:
            return "Ali Baba, a humble woodcutter who once spoke the words \"Open Sesame\" and found a den of forty thieves, is now Zahara's foremost seeker of hidden caves and buried fortune. He trades in rumors of rare treasure and can tell a true map from a forger's trick. Win his trust and the secret places of the desert open to you — and at the height of your friendship, he will walk the dungeons at your side."
        case .jasmine:
            return "Jasmine, a noblewoman of Sinbad's court, is the conscience of Zahara — beloved by its people and respected in the palace halls. Where others draw swords she offers words, ending feuds that armies could not. Earn her friendship and the nobles, the citizens, and the king himself grow warmer to you. Those who win her deepest trust are named protectors of the city she loves."
        case .aladdin:
            return "Aladdin, a street urchin turned adventurer, knows every alley of Zahara and every rumor that runs through them. Drawn to magic lamps and Djinn artifacts, he braves dungeons others would flee. Befriend him and magical wonders find their way into your hands; earn his loyalty and no trap will catch you unaware. It is said he guards the secret of a second lamp — and the Djinn bound within it."
        }
    }

    /// The concrete benefit granted *at* a given tier (nil below Friendly).
    func benefit(at tier: CharacterTier) -> String? {
        guard tier >= .friendly else { return nil }
        switch (self, tier) {
        case (.aliBaba, .friendly):  return "Better treasure-search fortune"
        case (.aliBaba, .trusted):   return "Hidden-cave quests & sharper dungeon searches"
        case (.aliBaba, .loyal):     return "Can join you as a dungeon companion"
        case (.aliBaba, .legendary): return "Unlocks the Hidden Caves treasure ending"
        case (.jasmine, .friendly):  return "Extra Honor from palace visits"
        case (.jasmine, .trusted):   return "Diplomacy quests & easier palace entry"
        case (.jasmine, .loyal):     return "Safer palace events — the court shields you"
        case (.jasmine, .legendary): return "Unlocks the Protector of Zahara ending"
        case (.aladdin, .friendly):  return "Better chance to find magical items"
        case (.aladdin, .trusted):   return "Artifact quests & Djinn-artifact clues"
        case (.aladdin, .loyal):     return "Dungeon companion; fewer trap wounds"
        case (.aladdin, .legendary): return "Unlocks the rare Djinn-artifact questline"
        default: return nil
        }
    }

    /// Every benefit unlocked up to and including the current tier.
    func benefits(upTo tier: CharacterTier) -> [String] {
        [CharacterTier.friendly, .trusted, .loyal, .legendary]
            .filter { $0 <= tier }
            .compactMap { benefit(at: $0) }
    }
}
