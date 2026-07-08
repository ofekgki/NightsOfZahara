//
//  RareAndStoryEvents.swift
//  Nights Of Zahara
//
//  Rare, conditional events and branching story choices whose consequences
//  persist through the rest of the playthrough (via meta.majorChoices).
//

import Foundation

// MARK: - Rare conditional events

enum RareEvents {
    /// A rare event that only fires when its specific condition is met.
    static func maybeTrigger(for s: GameState) -> GameEvent? {
        var pool: [GameEvent] = []

        if s.stats.luck >= 25 { pool.append(luckyStar) }
        if s.stats.endurance <= 6 { pool.append(desperateBargain) }
        if s.djinns.contains(.zagan) { pool.append(gardenVision) }
        if s.meta.relationship("sinbad") >= 20 { pool.append(kingsSecret) }
        if s.meta.blessing?.kind == .curse { pool.append(brokenCurse) }
        if s.role == .storyteller && s.stats.reputation >= 40 { pool.append(royalSummons) }

        guard !pool.isEmpty, Int.random(in: 0..<100) < 22 else { return nil }
        return pool.randomElement()
    }

    static let luckyStar = GameEvent(
        title: "Under a Lucky Star",
        text: "A shooting star streaks over Zahara. The old folk say such a night grants a single wish.",
        options: [
            EventOption(label: "Wish for fortune") { s in
                let g = Int.random(in: 150...350); s.gold += g
                return "Gold rains into your hands. +\(g) Gold."
            },
            EventOption(label: "Wish for a clue") { s in
                s.pendingDungeonClues += 2
                return "Visions of a hidden dungeon fill your dreams. +2 Clues."
            }
        ])

    static let desperateBargain = GameEvent(
        title: "A Desperate Bargain",
        text: "Wounded and weary, you meet a shrouded healer who offers strength — for a price.",
        options: [
            EventOption(label: "Accept the healing (−80 gold)") { s in
                guard s.gold >= 80 else { return "You cannot pay the healer's price." }
                s.gold -= 80; s.meta.injuries = 0; s.stats.endurance += 4
                return "Your wounds close. Injuries mended, +4 Endurance."
            },
            EventOption(label: "Refuse") { _ in "You limp away, unwilling to pay." }
        ])

    static let gardenVision = GameEvent(
        title: "Vision of the Garden",
        text: "Zagan, Djinn of Life, shows you a garden blooming in the wasteland — a place of renewal.",
        options: [
            EventOption(label: "Walk the garden path") { s in
                s.stats.luck += 3; s.meta.injuries = max(0, s.meta.injuries - 2)
                return "Life flows through you. +3 Luck, wounds ease."
            }
        ])

    static let kingsSecret = GameEvent(
        title: "The King's Secret",
        text: "Sinbad confides in you alone: a map to a treasure he could never reach in his sailing days.",
        options: [
            EventOption(label: "Accept the map") { s in
                s.pendingDungeonClues += 2; s.gold += 100
                s.meta.relationships["sinbad", default: 0] += 4
                return "The king's trust deepens. +2 Clues, +100 Gold."
            }
        ])

    static let brokenCurse = GameEvent(
        title: "Breaking the Curse",
        text: "A wandering dervish offers to lift the ill fortune that clings to you tonight.",
        options: [
            EventOption(label: "Accept his blessing") { s in
                s.meta.blessing = nil
                return "The curse is lifted from your shoulders."
            },
            EventOption(label: "Endure it") { s in
                s.stats.courage += 2
                return "You bear the curse with grit. +2 Courage."
            }
        ])

    static let royalSummons = GameEvent(
        title: "A Storyteller's Fame",
        text: "Your fame as a storyteller reaches the palace. Nobles clamor for a private performance.",
        options: [
            EventOption(label: "Perform for the court") { s in
                s.gold += 200; s.stats.honor += 5; s.palaceUnlocked = true
                return "The court is spellbound. +200 Gold, +5 Honor, palace opened."
            }
        ])
}

// MARK: - Branching story choices

enum StoryChoices {
    /// Returns a pending story choice for this night, if one is due and unmade.
    static func pending(for s: GameState) -> GameEvent? {
        for choice in all where choice.night == s.night && !s.meta.majorChoices.contains(choice.id) {
            return choice.event
        }
        return nil
    }

    private struct Choice { let id: String; let night: Int; let event: GameEvent }

    private static let all: [Choice] = [
        Choice(id: "choice_thieves", night: 5, event: GameEvent(
            title: "A Crossroads of Loyalty",
            text: "The Thieves' Guild offers you a place among them — but the Palace Guards would frown on such company. Where do your loyalties lie?",
            options: [
                EventOption(label: "Join the thieves") { s in
                    s.meta.majorChoices.append("choice_thieves")
                    s.meta.majorChoices.append("path_thief")
                    s.meta.factions["thieves", default: 0] += 20
                    s.meta.factions["guards", default: 0] -= 10
                    s.stats.cunning += 4
                    return "You clasp hands in shadow. The guild is yours; the guards grow wary. +4 Cunning."
                },
                EventOption(label: "Side with the guards") { s in
                    s.meta.majorChoices.append("choice_thieves")
                    s.meta.majorChoices.append("path_guard")
                    s.meta.factions["guards", default: 0] += 20
                    s.meta.factions["thieves", default: 0] -= 10
                    s.stats.honor += 4
                    return "You report the offer to the guard captain. Honor rises; the guild remembers. +4 Honor."
                }
            ])),

        Choice(id: "choice_relic", night: 20, event: GameEvent(
            title: "The Merchant's Relic",
            text: "A dying merchant entrusts you with a sacred relic. Do you return it to the temple, or sell it for a fortune?",
            options: [
                EventOption(label: "Return it to the temple") { s in
                    s.meta.majorChoices.append("choice_relic")
                    s.meta.majorChoices.append("relic_returned")
                    s.stats.honor += 6
                    s.meta.relationships["scheherazade", default: 0] += 5
                    s.meta.factions["nobles", default: 0] += 10
                    return "The temple honors your virtue. +6 Honor, Scheherazade's respect grows."
                },
                EventOption(label: "Sell it for gold") { s in
                    s.meta.majorChoices.append("choice_relic")
                    s.meta.majorChoices.append("relic_sold")
                    s.gold += 400
                    s.meta.factions["nobles", default: 0] -= 8
                    return "A fortune fills your purse, but whispers follow you. +400 Gold."
                }
            ])),

        Choice(id: "choice_djinn_war", night: 45, event: GameEvent(
            title: "The Djinn's Bargain",
            text: "An imprisoned Djinn offers great power in exchange for its freedom — but Scheherazade warns of the cost.",
            options: [
                EventOption(label: "Free the Djinn") { s in
                    s.meta.majorChoices.append("choice_djinn_war")
                    s.meta.majorChoices.append("djinn_freed")
                    s.stats.magic += 8
                    s.meta.factions["djinnSpirits", default: 0] += 15
                    s.meta.relationships["scheherazade", default: 0] -= 5
                    return "Power surges through you, though Scheherazade turns away. +8 Magic."
                },
                EventOption(label: "Heed Scheherazade") { s in
                    s.meta.majorChoices.append("choice_djinn_war")
                    s.meta.majorChoices.append("djinn_bound")
                    s.stats.wisdom += 5
                    s.meta.relationships["scheherazade", default: 0] += 6
                    return "You leave the Djinn bound. Scheherazade nods gravely. +5 Wisdom."
                }
            ]))
    ]
}
