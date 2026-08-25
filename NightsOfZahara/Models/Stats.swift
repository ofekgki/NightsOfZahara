//  The character stats and a small helper enum for iterating /
//  displaying them in the UI.

import SwiftUI

/// The numerical character stats described in the spec.
struct Stats: Codable, Equatable {
    var wealth: Int
    var wisdom: Int
    var magic: Int
    var reputation: Int
    var honor: Int
    var luck: Int
    var courage: Int
    var cunning: Int
    var endurance: Int
    /// Speed — combat order, escape chance, some dungeon events and journeys.
    /// Defaults to 0 so the memberwise initializer can omit it (e.g. equip
    /// bonuses); characters get a baseline via `Stats.baseline`.
    var speed: Int = 0

    /// The absolute ceiling for any single stat.
    static let cap = 125

    static let zero = Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0,
                            honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 0, speed: 0)

    /// A modest baseline every character starts with, before role bonuses.
    static let baseline = Stats(wealth: 5, wisdom: 5, magic: 5, reputation: 5,
                                honor: 5, luck: 5, courage: 5, cunning: 5, endurance: 10, speed: 5)

    subscript(_ kind: StatKind) -> Int {
        get {
            switch kind {
            case .wealth:     return wealth
            case .wisdom:     return wisdom
            case .magic:      return magic
            case .reputation: return reputation
            case .honor:      return honor
            case .luck:       return luck
            case .courage:    return courage
            case .cunning:    return cunning
            case .endurance:  return endurance
            case .speed:      return speed
            }
        }
        set {
            let v = min(Stats.cap, max(0, newValue))
            switch kind {
            case .wealth:     wealth = v
            case .wisdom:     wisdom = v
            case .magic:      magic = v
            case .reputation: reputation = v
            case .honor:      honor = v
            case .luck:       luck = v
            case .courage:    courage = v
            case .cunning:    cunning = v
            case .endurance:  endurance = v
            case .speed:      speed = v
            }
        }
    }

    /// Adds another Stats value (used for role bonuses / upgrades).
    static func + (lhs: Stats, rhs: Stats) -> Stats {
        Stats(wealth: lhs.wealth + rhs.wealth,
              wisdom: lhs.wisdom + rhs.wisdom,
              magic: lhs.magic + rhs.magic,
              reputation: lhs.reputation + rhs.reputation,
              honor: lhs.honor + rhs.honor,
              luck: lhs.luck + rhs.luck,
              courage: lhs.courage + rhs.courage,
              cunning: lhs.cunning + rhs.cunning,
              endurance: lhs.endurance + rhs.endurance,
              speed: lhs.speed + rhs.speed)
    }

    var highest: StatKind {
        StatKind.allCases.max { self[$0] < self[$1] } ?? .endurance
    }

    // Explicit keys so the custom decoder below can tolerate a missing "speed"
    // in older saves (which predate the Speed stat).
    enum CodingKeys: String, CodingKey {
        case wealth, wisdom, magic, reputation, honor, luck, courage, cunning, endurance, speed
    }
}

extension Stats {
    /// Backward-compatible decoder: saves made before the Speed stat lack the
    /// "speed" key, so it falls back to the baseline value.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wealth     = try c.decode(Int.self, forKey: .wealth)
        wisdom     = try c.decode(Int.self, forKey: .wisdom)
        magic      = try c.decode(Int.self, forKey: .magic)
        reputation = try c.decode(Int.self, forKey: .reputation)
        honor      = try c.decode(Int.self, forKey: .honor)
        luck       = try c.decode(Int.self, forKey: .luck)
        courage    = try c.decode(Int.self, forKey: .courage)
        cunning    = try c.decode(Int.self, forKey: .cunning)
        endurance  = try c.decode(Int.self, forKey: .endurance)
        speed      = (try? c.decodeIfPresent(Int.self, forKey: .speed)) ?? 5
    }
}

/// Identifies a single stat — used for iteration, icons, labels and upgrades.
enum StatKind: String, CaseIterable, Codable, Identifiable {
    case wealth, wisdom, magic, reputation, honor, luck, courage, cunning, endurance, speed

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .wealth:     return "banknote"
        case .wisdom:     return "book.closed"
        case .magic:      return "sparkles"
        case .reputation: return "person.2"
        case .honor:      return "crown"
        case .luck:       return "die.face.5"
        case .courage:    return "flame"
        case .cunning:    return "eye"
        case .endurance:  return "heart"
        case .speed:      return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .wealth:     return Theme.gold
        case .wisdom:     return .cyan
        case .magic:      return .purple
        case .reputation: return .orange
        case .honor:      return Theme.brightGold
        case .luck:       return .green
        case .courage:    return Theme.ember
        case .cunning:    return .indigo
        case .endurance:  return .red
        case .speed:      return .mint
        }
    }

    /// A short explanation of what the stat governs (for info tooltips).
    var explanation: String {
        switch self {
        case .wealth:     return "Reflects your economic standing. Rises and falls with the gold you hold, and boosts your income from Work."
        case .wisdom:     return "Knowledge and insight. Helps with studying, puzzles and dungeon searches."
        case .magic:      return "Arcane power. Aids Djinn chambers, magical events and spellcraft."
        case .reputation: return "How widely your name is known. Opens doors and improves social outcomes."
        case .honor:      return "Your standing with the court. Grants access to Sinbad's palace."
        case .luck:       return "Fortune's favor. Nudges nearly every roll in your direction."
        case .courage:    return "Bravery in a fight. The core of combat and monster rooms."
        case .cunning:    return "Guile and street-smarts. Powers treasure-hunting and traps."
        case .endurance:  return "Stamina and toughness. Absorbs wounds; running low forces retreat."
        case .speed:      return "Quickness. Improves combat order, escape chance, dungeon reflexes and journeys. Heavy gear can reduce it."
        }
    }
}
