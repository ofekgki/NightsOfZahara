//
//  HomeRoom.swift
//  Nights Of Zahara
//
//  The player's home in Zahara and the rooms they can build/upgrade for
//  long-term passive bonuses.
//

import SwiftUI

enum HomeRoom: String, CaseIterable, Identifiable, Codable {
    case resting, library, training, magic, storage, treasure, crafting, map, guest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resting:  return "Resting Room"
        case .library:  return "Library"
        case .training: return "Training Room"
        case .magic:    return "Magic Room"
        case .storage:  return "Storage Room"
        case .treasure: return "Treasure Room"
        case .crafting: return "Crafting Room"
        case .map:      return "Map Room"
        case .guest:    return "Guest Room"
        }
    }

    var icon: String {
        switch self {
        case .resting:  return "bed.double.fill"
        case .library:  return "books.vertical.fill"
        case .training: return "figure.strengthtraining.traditional"
        case .magic:    return "wand.and.stars"
        case .storage:  return "archivebox.fill"
        case .treasure: return "shippingbox.fill"
        case .crafting: return "hammer.fill"
        case .map:      return "map.fill"
        case .guest:    return "person.2.fill"
        }
    }

    var benefit: String {
        switch self {
        case .resting:  return "+1 Energy restored when you Rest, per level."
        case .library:  return "+1 Wisdom from Study, per level."
        case .training: return "+1 Courage from Training, per level."
        case .magic:    return "+1 Magic from Study, per level."
        case .storage:  return "+1 Magical Dust from finds, per level."
        case .treasure: return "+10% treasure-search fortune, per level."
        case .crafting: return "Crafting & reforging cost less, per level."
        case .map:      return "+1 dungeon-search fortune, per level."
        case .guest:    return "Lets you host companions (level 1 required)."
        }
    }

    var maxLevel: Int { 3 }

    /// Gold cost to raise this room to `targetLevel`.
    func cost(toLevel targetLevel: Int) -> Int {
        200 * targetLevel + 100
    }
}

/// Which gameplay aspect a home bonus applies to.
enum HomeAspect { case rest, study, magicStudy, train, dust, treasure, craftDiscount, dungeonSearch }
