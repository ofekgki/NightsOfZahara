//
//  GameViewModel+Characters.swift
//  Nights Of Zahara
//
//  Relationship bonuses and bond-building for the major characters
//  (Ali Baba, Jasmine, Aladdin) and how they feed into the action resolvers.
//

import SwiftUI

extension GameViewModel {

    // MARK: - Bond queries

    func bond(_ c: MajorCharacter) -> Int { state?.meta.relationship(c.relationshipKey) ?? 0 }
    func tier(_ c: MajorCharacter) -> CharacterTier { CharacterTier.from(bond(c)) }
    func hasMet(_ c: MajorCharacter) -> Bool { bond(c) > 0 }

    // MARK: - Ali Baba (treasure & hidden caves)

    /// Added to treasure-search rolls once Ali Baba is Friendly+.
    var aliBabaTreasureBonus: Int {
        let t = tier(.aliBaba); return t >= .friendly ? t.rawValue * 4 : 0
    }
    /// Added to dungeon-search rolls (hidden caves) once Ali Baba is Trusted+.
    var aliBabaCaveBonus: Int {
        let t = tier(.aliBaba); return t >= .trusted ? t.rawValue * 3 : 0
    }

    // MARK: - Aladdin (magical items & dungeons)

    /// Percentage points added to the chance of finding a magical item.
    var aladdinMagicFindBonus: Int {
        let t = tier(.aladdin); return t >= .friendly ? t.rawValue * 6 : 0
    }
    /// Reduces the wound taken from a failed dungeon room (fewer trap injuries).
    var aladdinDungeonSafety: Int {
        let t = tier(.aladdin)
        if t >= .loyal { return 2 }
        if t >= .trusted { return 1 }
        return 0
    }

    // MARK: - Jasmine (palace & diplomacy)

    /// Bonus Honor earned on a successful palace visit (Friendly+).
    var jasminePalaceHonor: Int {
        let t = tier(.jasmine); return t >= .friendly ? t.rawValue : 0
    }
    /// Lowers the Honor required to enter the palace (Trusted+).
    var jasmineEntryEase: Int {
        let t = tier(.jasmine); return t >= .trusted ? t.rawValue : 0
    }
    /// Tilts palace-event rolls toward safer outcomes (Loyal+).
    var jasmineFavorBoost: Int {
        let t = tier(.jasmine); return t >= .loyal ? t.rawValue * 6 : 0
    }

    // MARK: - Bond growth

    /// Grow bonds with the major characters through relevant nightly actions,
    /// mirroring how factions gain favor.
    func creditCharacters(for action: NightAction) {
        guard var s = state else { return }
        switch action {
        case .searchTreasure: bumpRelationship("alibaba", 1, in: &s)
        case .journey:        bumpRelationship("alibaba", 1, in: &s)
        case .palace:         bumpRelationship("jasmine", 1, in: &s)
        case .connections:    bumpRelationship("jasmine", 1, in: &s)
        case .searchDungeon:  bumpRelationship("aladdin", 1, in: &s)
        default: break
        }
        state = s
    }
}
