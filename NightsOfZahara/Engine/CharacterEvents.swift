//  Dialogue events for the major characters. Each character has a one-time
//  introduction (fired when the player first crosses its path) and recurring
//  bond-deepening encounters that raise the relationship and offer choices.

import Foundation

enum CharacterEvents {

    /// Pick a character dialogue event for tonight, if one is due.
    static func maybeTrigger(for s: GameState) -> GameEvent? {
        func bond(_ key: String) -> Int { s.meta.relationship(key) }

        // Introductions take priority and are guaranteed once conditions are met.
        if bond("alibaba") == 0 && s.treasuresFound >= 2 { return meetAliBaba }
        if bond("jasmine") == 0 && s.palaceUnlocked { return meetJasmine }
        if bond("aladdin") == 0 && (!s.discoveredDungeons.isEmpty || s.stats.magic >= 12) { return meetAladdin }

        // Otherwise, occasionally deepen a bond the player has already begun.
        guard Int.random(in: 0..<100) < 20 else { return nil }
        var pool: [GameEvent] = []
        if bond("alibaba") > 0 { pool.append(aliBabaBond) }
        if bond("jasmine") > 0 { pool.append(jasmineBond) }
        if bond("aladdin") > 0 { pool.append(aladdinBond) }
        return pool.randomElement()
    }

    // MARK: - Introductions

    static let meetAliBaba = GameEvent(
        title: "A Stranger at the Bazaar",
        text: "A sharp-eyed man watches you count your treasures. \"Ali Baba,\" he says, offering his hand. \"I know where the desert hides its gold — and I could use a friend with your luck.\"",
        options: [
            EventOption(label: "Clasp his hand — befriend him") { s in
                s.meta.relationships["alibaba", default: 0] += 10
                s.pendingDungeonClues += 1
                return "Ali Baba grins. You have made a valuable friend. +1 Dungeon Clue."
            },
            EventOption(label: "Stay wary of the stranger") { s in
                s.meta.relationships["alibaba", default: 0] += 2
                return "You nod politely. Ali Baba tips his hat and melts into the crowd."
            }
        ])

    static let meetJasmine = GameEvent(
        title: "A Voice in the Palace",
        text: "Amid the marble columns, a noblewoman speaks gently with a water-seller as if with a prince. She turns to you. \"I am Jasmine. Zahara is its people, not its throne. Will you help me serve them?\"",
        options: [
            EventOption(label: "Pledge to help her people") { s in
                s.meta.relationships["jasmine", default: 0] += 10
                s.stats.honor += 2
                return "Jasmine smiles warmly. A powerful ally at court. +2 Honor."
            },
            EventOption(label: "Offer only a polite bow") { s in
                s.meta.relationships["jasmine", default: 0] += 2
                return "You bow and move on. Jasmine watches you go, thoughtful."
            }
        ])

    static let meetAladdin = GameEvent(
        title: "A Thief on the Rooftops",
        text: "A grinning youth drops from a rooftop, an oil lamp tucked under one arm. \"Aladdin. I hear you go where the Djinns sleep. Stick with me and I'll show you wonders — the streets keep the best secrets.\"",
        options: [
            EventOption(label: "Take him up on it") { s in
                s.meta.relationships["aladdin", default: 0] += 10
                s.stats.magic += 1
                return "Aladdin laughs and claps your shoulder. A daring new friend. +1 Magic."
            },
            EventOption(label: "Keep your distance") { s in
                s.meta.relationships["aladdin", default: 0] += 2
                return "You wave him off. He shrugs and vanishes over the rooftops."
            }
        ])

    // MARK: - Bond deepening

    static let aliBabaBond = GameEvent(
        title: "Ali Baba's Map",
        text: "Ali Baba spreads two treasure maps on the table. \"One is true, one a forger's trick. A friend deserves the real one — but tell me first: do you trust my eye?\"",
        options: [
            EventOption(label: "Trust his eye") { s in
                s.meta.relationships["alibaba", default: 0] += 6
                s.pendingDungeonClues += 2
                return "He hands you the true map with a wink. +2 Dungeon Clues."
            },
            EventOption(label: "Buy both to be safe (−60 gold)") { s in
                guard s.gold >= 60 else { return "You cannot spare the coin; he keeps his maps." }
                s.gold -= 60
                s.meta.relationships["alibaba", default: 0] += 3
                s.pendingDungeonClues += 1
                return "Cautious, but he respects it. +1 Dungeon Clue."
            }
        ])

    static let jasmineBond = GameEvent(
        title: "Jasmine's Request",
        text: "\"Two merchant families are near to blows,\" Jasmine says. \"A war in the market would ruin a hundred honest folk. Will you help me broker peace instead?\"",
        options: [
            EventOption(label: "Broker the peace") { s in
                s.meta.relationships["jasmine", default: 0] += 6
                s.stats.reputation += 3; s.stats.honor += 2
                s.meta.factions["citizens", default: 0] += 5
                return "The families clasp hands. Zahara breathes easier. +3 Reputation, +2 Honor."
            },
            EventOption(label: "Let them settle it themselves") { s in
                s.meta.relationships["jasmine", default: 0] += 1
                return "Jasmine sighs. \"Not every battle needs a blade — but as you wish.\""
            }
        ])

    static let aladdinBond = GameEvent(
        title: "Aladdin's Shortcut",
        text: "\"There's a Djinn artifact down an old cistern,\" Aladdin whispers, \"but the way is trapped. I know the safe path — trust me and we split whatever we find.\"",
        options: [
            EventOption(label: "Follow his lead") { s in
                s.meta.relationships["aladdin", default: 0] += 6
                let g = Int.random(in: 60...140); s.gold += g
                return "His shortcut pays off — coin and a rush of magic. +\(g) Gold."
            },
            EventOption(label: "Go your own careful way") { s in
                s.meta.relationships["aladdin", default: 0] += 2
                s.stats.cunning += 1
                return "You pick your own path. Slower, but you learn its tricks. +1 Cunning."
            }
        ])
}
