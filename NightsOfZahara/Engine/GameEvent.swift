//
//  GameEvent.swift
//  Nights Of Zahara
//
//  Transient random events that can appear between nights. Events are not
//  persisted — they resolve immediately through the player's choice.
//

import Foundation

struct EventOption: Identifiable {
    let id = UUID()
    let label: String
    /// Mutates the state and returns a short result line for the journal.
    let apply: (inout GameState) -> String
}

struct GameEvent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let options: [EventOption]
}

enum RandomEvents {

    /// Roughly a 45% chance to surface an event when a new night begins.
    static func maybeTrigger(for state: GameState) -> GameEvent? {
        guard Int.random(in: 0..<100) < 45 else { return nil }
        return pool(for: state).randomElement()
    }

    private static func pool(for state: GameState) -> [GameEvent] {
        var events: [GameEvent] = [mysteriousMerchant, marketChild, ancientRumor, sandstorm, storyContest]
        if state.stats.honor >= 15 || state.palaceUnlocked {
            events.append(palaceInvitation)
        }
        if state.night > 100 {
            events.append(whisperingLamp)
        }
        return events
    }

    // MARK: - Event definitions

    static let mysteriousMerchant = GameEvent(
        title: "A Mysterious Merchant",
        text: "A hooded merchant unfurls a rug of curiosities. \"A charm of fortune,\" he rasps, \"for only 60 gold.\"",
        options: [
            EventOption(label: "Buy the charm (60 gold)") { s in
                guard s.gold >= 60 else { return "You could not afford the charm." }
                s.gold -= 60
                s.stats.luck += 3
                return "You bought the charm. +3 Luck."
            },
            EventOption(label: "Decline politely") { _ in
                "You wave the merchant away and keep your gold."
            }
        ]
    )

    static let marketChild = GameEvent(
        title: "A Child in the Market",
        text: "A ragged child tugs your sleeve, begging for a coin to feed their family.",
        options: [
            EventOption(label: "Give 20 gold") { s in
                guard s.gold >= 20 else { return "Your purse was too light to help." }
                s.gold -= 20
                s.stats.honor += 3
                s.stats.reputation += 2
                return "Word of your kindness spreads. +3 Honor, +2 Reputation."
            },
            EventOption(label: "Walk on by") { s in
                s.stats.honor = max(0, s.stats.honor - 1)
                return "You keep your coin. A little of your honor fades. -1 Honor."
            }
        ]
    )

    static let ancientRumor = GameEvent(
        title: "A Rumor by the Well",
        text: "Sailors whisper of a dungeon hidden beyond the dunes, its entrance sealed for a thousand years.",
        options: [
            EventOption(label: "Listen closely") { s in
                s.pendingDungeonClues += 1
                return "You gather a clue. Your next dungeon search will be sharper."
            },
            EventOption(label: "Dismiss it as tavern talk") { _ in
                "You shrug off the rumor and move on."
            }
        ]
    )

    static let sandstorm = GameEvent(
        title: "A Sudden Sandstorm",
        text: "The sky turns copper as a sandstorm sweeps through Zahara. The streets empty.",
        options: [
            EventOption(label: "Shelter and wait (−1 Energy)") { s in
                s.energy = max(0, s.energy - 1)
                return "You lose an hour of the night sheltering. -1 Energy."
            },
            EventOption(label: "Brave the storm for a shortcut") { s in
                if s.stats.endurance + Int.random(in: 0...10) > 15 {
                    s.gold += 40
                    return "You push through and find a dropped purse. +40 Gold."
                } else {
                    s.stats.endurance = max(0, s.stats.endurance - 2)
                    return "The storm batters you. -2 Endurance."
                }
            }
        ]
    )

    static let storyContest = GameEvent(
        title: "A Storytelling Contest",
        text: "The tea house announces a contest. The finest tale wins gold and renown.",
        options: [
            EventOption(label: "Enter the contest") { s in
                let roll = s.stats.wisdom + s.stats.reputation + Int.random(in: 0...12)
                if roll > 24 {
                    s.gold += 80
                    s.stats.reputation += 4
                    return "Your tale enthralls the crowd! +80 Gold, +4 Reputation."
                } else {
                    s.stats.reputation += 1
                    return "A respectable showing. +1 Reputation."
                }
            },
            EventOption(label: "Watch from the crowd") { _ in
                "You enjoy the tales and slip away."
            }
        ]
    )

    static let palaceInvitation = GameEvent(
        title: "A Palace Invitation",
        text: "A guard in Sinbad's colors presents a sealed scroll — an invitation to the palace.",
        options: [
            EventOption(label: "Accept with a bow") { s in
                s.palaceUnlocked = true
                s.stats.honor += 3
                return "The palace gates are open to you. +3 Honor."
            }
        ]
    )

    static let whisperingLamp = GameEvent(
        title: "A Whispering Lamp",
        text: "In a dusty stall, an old lamp seems to murmur your name. Scheherazade would call this an omen.",
        options: [
            EventOption(label: "Take the lamp") { s in
                s.pendingDungeonClues += 2
                s.stats.magic += 2
                return "The lamp guides your search. +2 Magic, and 2 dungeon clues."
            },
            EventOption(label: "Leave it be") { _ in
                "You resist the whisper and leave the lamp behind."
            }
        ]
    )
}
