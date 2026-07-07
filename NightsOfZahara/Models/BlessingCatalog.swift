//
//  BlessingCatalog.swift
//  Nights Of Zahara
//
//  The pool of nightly blessings and curses. One may be granted at the start
//  of a night, affecting that night's fortunes.
//

import Foundation

enum BlessingCatalog {
    static let all: [DailyModifier] = [
        DailyModifier(id: "desert_moon", name: "Blessing of the Desert Moon",
                      flavor: "The moon smiles upon your path tonight.",
                      kind: .blessing, icon: "moon.stars.fill", luck: 5),
        DailyModifier(id: "palace_favor", name: "Palace Favor",
                      flavor: "Sinbad's court speaks well of you.",
                      kind: .blessing, icon: "crown.fill", combatBonus: 0, shopDiscount: 15),
        DailyModifier(id: "djinn_whisper", name: "Djinn Whisper",
                      flavor: "An unseen Djinn murmurs of hidden places.",
                      kind: .blessing, icon: "sparkles", dungeonClueBonus: 1),
        DailyModifier(id: "merchants_luck", name: "Merchant's Luck",
                      flavor: "Fortune favors your searching hands.",
                      kind: .blessing, icon: "bag.fill", treasureBonus: 20),
        DailyModifier(id: "restful_stars", name: "Restful Stars",
                      flavor: "The night air soothes your weary bones.",
                      kind: .blessing, icon: "bed.double.fill", energyDelta: 1, restBonus: 1),
        DailyModifier(id: "warriors_vigor", name: "Warrior's Vigor",
                      flavor: "Your blood runs hot for battle.",
                      kind: .blessing, icon: "flame.fill", combatBonus: 5),

        DailyModifier(id: "silent_sands", name: "Curse of the Silent Sands",
                      flavor: "The sands swallow all you seek.",
                      kind: .curse, icon: "aqi.low", treasureBonus: -25),
        DailyModifier(id: "ill_wind", name: "Ill Wind",
                      flavor: "A sour wind saps your strength.",
                      kind: .curse, icon: "wind", energyDelta: -1, combatBonus: -3),
        DailyModifier(id: "greedy_market", name: "Greedy Market",
                      flavor: "Merchants sense your need and gouge their prices.",
                      kind: .curse, icon: "cart.badge.minus", shopDiscount: -15),
        DailyModifier(id: "clouded_sight", name: "Clouded Sight",
                      flavor: "Your fortune dims like a fading lamp.",
                      kind: .curse, icon: "eye.slash", luck: -4)
    ]

    /// Maybe grant a modifier for the coming night (about 40% chance).
    static func roll(luckAffinity: Int) -> DailyModifier? {
        guard Int.random(in: 0..<100) < 40 else { return nil }
        // Higher luck tilts toward blessings.
        let blessings = all.filter { $0.kind == .blessing }
        let curses = all.filter { $0.kind == .curse }
        let blessingChance = min(85, 50 + luckAffinity / 3)
        if Int.random(in: 0..<100) < blessingChance {
            return blessings.randomElement()
        } else {
            return curses.randomElement()
        }
    }
}
