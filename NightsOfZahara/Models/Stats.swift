//
//  Stats.swift
//  Nights Of Zahara
//
//  The nine character stats and a small helper enum for iterating /
//  displaying them in the UI.
//

import SwiftUI

/// The nine numerical character stats described in the spec.
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

    static let zero = Stats(wealth: 0, wisdom: 0, magic: 0, reputation: 0,
                            honor: 0, luck: 0, courage: 0, cunning: 0, endurance: 0)

    /// A modest baseline every character starts with, before role bonuses.
    static let baseline = Stats(wealth: 5, wisdom: 5, magic: 5, reputation: 5,
                                honor: 5, luck: 5, courage: 5, cunning: 5, endurance: 10)

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
            }
        }
        set {
            let v = max(0, newValue)
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
              endurance: lhs.endurance + rhs.endurance)
    }

    var highest: StatKind {
        StatKind.allCases.max { self[$0] < self[$1] } ?? .endurance
    }
}

/// Identifies a single stat — used for iteration, icons, labels and upgrades.
enum StatKind: String, CaseIterable, Codable, Identifiable {
    case wealth, wisdom, magic, reputation, honor, luck, courage, cunning, endurance

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
        }
    }
}
