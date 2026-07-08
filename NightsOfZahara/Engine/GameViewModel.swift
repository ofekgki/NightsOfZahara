//
//  GameViewModel.swift
//  Nights Of Zahara
//
//  The game engine (MVVM). Owns the GameState, resolves nightly actions,
//  runs dungeons, handles combat/events and drives persistence.
//

import SwiftUI
import Combine

// MARK: - Presentation helpers

enum OutcomeTone {
    case good, bad, neutral, epic

    var color: Color {
        switch self {
        case .good:    return Theme.success
        case .bad:     return Theme.danger
        case .neutral: return Theme.sand
        case .epic:    return Theme.brightGold
        }
    }

    var icon: String {
        switch self {
        case .good:    return "checkmark.seal.fill"
        case .bad:     return "xmark.octagon.fill"
        case .neutral: return "circle.dashed"
        case .epic:    return "sparkles"
        }
    }
}

struct ActionOutcome: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    var deltas: [String] = []
    var tone: OutcomeTone = .neutral
}

/// Live state of an in-progress dungeon crawl.
struct DungeonRun {
    var dungeon: Dungeon
    var roomIndex: Int = 0
    var log: [String] = []
    var finished: Bool = false
    var conquered: Bool = false
    var rewardClaimed: Bool = false
    /// Djinn abilities already invoked this run (by raw value).
    var abilitiesUsed: Set<String> = []

    var currentRoom: DungeonRoom? {
        roomIndex < dungeon.rooms.count ? dungeon.rooms[roomIndex] : nil
    }
    var progress: Double {
        dungeon.rooms.isEmpty ? 0 : Double(roomIndex) / Double(dungeon.rooms.count)
    }
}

enum GamePhase {
    case onboarding
    case playing
    case ended
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var state: GameState?
    @Published var phase: GamePhase = .onboarding

    // Transient UI state
    @Published var outcome: ActionOutcome?
    @Published var pendingEvent: GameEvent?
    @Published var activeRun: DungeonRun?
    @Published var nightSummary: NightSummary?
    /// When set (to 100, 200, …), the grand journey retrospective is shown with
    /// "Continue" / "Finish the Journey" options instead of a nightly summary.
    @Published var journeyCheckpointNight: Int?
    /// An event queued to appear after the night-summary sheet is dismissed.
    var bufferedEvent: GameEvent?

    // Transient night-summary tracking (reset each night)
    var nightStartGold = 0
    var nightStartStats: Stats = .zero
    var nightStartInjuries = 0
    var nightEntries: [NightSummary.Entry] = []
    var nightEventLines: [String] = []

    /// True once the player has Rested this night — Rest is limited to once per turn.
    @Published var restedThisNight = false

    var hasSave: Bool { SaveManager.hasSave() }

    init() {
        if let saved = SaveManager.load() {
            state = saved
            phase = saved.isFinished ? .ended : .playing
            beginNightTracking()
        }
    }

    // MARK: - Lifecycle

    func continueGame() {
        if let saved = SaveManager.load() {
            state = saved
            phase = saved.isFinished ? .ended : .playing
            beginNightTracking()
        }
    }

    func startNewGame(name: String, role: Role) {
        var fresh = GameState.new(name: name, role: role)
        fresh.energy = fresh.energyForCurrentEra
        fresh.maxEnergy = fresh.energyForCurrentEra
        fresh.meta = MetaState()   // ensure expansion state is present
        state = fresh
        phase = .playing
        beginNightTracking()
        save()
    }

    /// Snapshot the current gold/stats/injuries so we can compute night deltas.
    func beginNightTracking() {
        guard let s = state else { return }
        nightStartGold = s.gold
        nightStartStats = s.stats
        nightStartInjuries = s.meta.injuries
        nightEntries = []
        nightEventLines = []
        restedThisNight = false
    }

    func abandonAndRestart() {
        SaveManager.deleteSave()
        state = nil
        activeRun = nil
        outcome = nil
        pendingEvent = nil
        phase = .onboarding
    }

    func save() {
        guard var s = state else { return }
        syncWealth(&s)
        clampStats(&s)
        state = s
        SaveManager.save(s)
    }

    /// Wealth tracks the player's actual fortune: it rises and falls with the
    /// gold they currently hold, rather than manual upgrades alone.
    private func syncWealth(_ s: inout GameState) {
        s.stats.wealth = min(Stats.cap, 5 + s.gold / 40)
    }

    /// Enforce the hard stat ceiling everywhere (e.g. after equipping gear).
    private func clampStats(_ s: inout GameState) {
        for k in StatKind.allCases { s.stats[k] = s.stats[k] }   // subscript clamps 0...cap
    }

    // MARK: - Djinn helpers

    private func has(_ djinn: Djinn) -> Bool {
        state?.djinns.contains(djinn) ?? false
    }

    // MARK: - Dice

    /// A stat check with a small random swing; luck nudges the result.
    /// Injuries sap the roll; an active blessing's luck helps.
    func check(_ value: Int, difficulty: Int, luck: Int = 0) -> Bool {
        let injuries = state?.meta.injuries ?? 0
        let blessLuck = state?.meta.blessing?.luck ?? 0
        let roll = value + Int.random(in: 0...12) + (luck + blessLuck) / 4 - injuries
        return roll >= difficulty
    }

    /// A delta line for a stat gain that reads "Honor - Max" once the stat is
    /// capped. Call AFTER applying the change, passing the post-change state.
    func statGainLabel(_ kind: StatKind, _ amount: Int, in s: GameState) -> String {
        s.stats[kind] >= Stats.cap ? "\(kind.title) - Max" : "+\(amount) \(kind.title)"
    }

    func present(_ outcome: ActionOutcome) {
        self.outcome = outcome
        addJournal(outcome.message)
        // Record for the night summary.
        nightEntries.append(NightSummary.Entry(title: outcome.title,
                                               deltas: outcome.deltas,
                                               tone: String(describing: outcome.tone)))
        HapticManager.forTone(outcome.tone)
        save()
    }

    func addJournal(_ line: String) {
        state?.journal.insert("Night \(state?.night ?? 0): \(line)", at: 0)
        if let count = state?.journal.count, count > 40 {
            state?.journal.removeLast(count - 40)
        }
    }

    // MARK: - Action dispatch

    /// Returns true if energy was available and the action resolved instantly.
    /// Screen-based actions (shop/upgrade/eat) return false — the caller opens a sheet.
    @discardableResult
    func perform(_ action: NightAction) -> Bool {
        guard var s = state else { return false }
        guard !action.opensScreen else { return false }

        // Rest is limited to once per night.
        if action == .rest, restedThisNight {
            outcome = ActionOutcome(title: "Already Rested",
                                    message: "You have already rested tonight. End the night for a full recovery.",
                                    tone: .bad)
            return true
        }

        // If every dungeon is already known, searching is pointless (no energy spent).
        if action == .searchDungeon, allDungeonsDiscovered {
            outcome = ActionOutcome(title: "Nothing Left to Find",
                                    message: "All known dungeons have already been discovered.",
                                    tone: .neutral)
            return true
        }

        // Energy cost is fixed per action (no Djinn/item discounts) so the UI,
        // confirmation and deduction always agree.
        let cost = action.energyCost

        guard s.energy >= cost else {
            outcome = ActionOutcome(title: "Too Tired",
                                    message: "You lack the energy for that. End the night to rest.",
                                    tone: .bad)
            return true
        }

        s.energy -= cost
        state = s

        switch action {
        case .work:           doWork()
        case .study:          doStudy()
        case .train:          doTrain()
        case .prowl:          doProwl()
        case .journey:        doJourney()
        case .searchDungeon:  doSearchDungeon()
        case .palace:         doPalace()
        case .connections:    doConnections()
        case .searchTreasure: doSearchTreasure()
        case .rest:           doRest()
        case .shop, .upgrade, .eat: break
        }
        creditFactions(for: action)
        creditCharacters(for: action)
        return true
    }

    // MARK: - Individual resolvers

    private func doWork() {
        guard var s = state else { return }
        var gold = Int.random(in: 30...70)
        var rep = 1
        switch s.role {
        case .merchant:    gold += 40
        case .storyteller: gold += 15; rep += 2
        case .sailor:      gold += 20
        default:           break
        }
        gold += s.stats.wealth
        gold += homeBonus(.workIncome) * 20     // Work Room income bonus
        if has(.zalmbur) { gold += 40 }         // Djinn of Merchants
        s.gold += gold
        s.stats.reputation += rep
        state = s
        SoundManager.shared.play(.coins)
        present(ActionOutcome(title: "A Night's Work",
                              message: "You earn your keep in Zahara's bustle.",
                              deltas: ["+\(gold) Gold", "+\(rep) Reputation"],
                              tone: .good))
    }

    private func doStudy() {
        guard var s = state else { return }
        let wis = Int.random(in: 1...3) + homeBonus(.study)
        let mag = (s.role == .wizardApprentice ? 2 : Int.random(in: 0...1)) + homeBonus(.magicStudy)
        s.stats.wisdom += wis
        s.stats.magic += mag
        state = s
        var deltas = [statGainLabel(.wisdom, wis, in: s)]
        if mag > 0 { deltas.append(statGainLabel(.magic, mag, in: s)) }
        present(ActionOutcome(title: "Study",
                              message: "You pore over scrolls of Djinn lore and ancient tongues.",
                              deltas: deltas, tone: .good))
    }

    private func doTrain() {
        guard var s = state else { return }
        let cour = Int.random(in: 1...3) + homeBonus(.train)
        let end = Int.random(in: 1...2)
        s.stats.courage += cour
        s.stats.endurance += end
        state = s
        present(ActionOutcome(title: "Training",
                              message: "Sweat and steel sharpen your body and nerve.",
                              deltas: [statGainLabel(.courage, cour, in: s), statGainLabel(.endurance, end, in: s)],
                              tone: .good))
    }

    /// Prowl Zahara's back alleys — sharpen Speed and Cunning.
    private func doProwl() {
        guard var s = state else { return }
        let spd = Int.random(in: 1...3)
        let cun = Int.random(in: 1...3) + (s.role == .marketOrphan ? 1 : 0)
        s.stats.speed += spd
        s.stats.cunning += cun
        state = s
        present(ActionOutcome(title: "Prowling the Alleys",
                              message: "You slip through Zahara's shadows, quick of foot and quicker of wit.",
                              deltas: [statGainLabel(.speed, spd, in: s), statGainLabel(.cunning, cun, in: s)],
                              tone: .good))
    }

    private func doJourney() {
        guard var s = state else { return }
        // Zawba'ah (Storms) and Paimon (Wind) master the desert roads.
        let djinnTravel = (has(.zawbaah) ? 8 : 0) + (has(.paimon) ? 6 : 0)
        let luckMod = (s.role == .sailor ? 6 : 0) + factionBonus(.sailors) * 2 + djinnTravel
        // Speed helps you cover more ground and slip past trouble on the road.
        let roll = Int.random(in: 0...100) + (s.stats.luck + luckMod) / 3 + s.stats.speed / 4
        if roll > 78 {
            // Discover a dungeon clue.
            s.pendingDungeonClues += 1
            state = s
            present(ActionOutcome(title: "A Fateful Path",
                                  message: "Beyond the dunes you spot ancient stonework — a clue to a hidden dungeon.",
                                  deltas: ["+1 Dungeon Clue"], tone: .epic))
        } else if roll > 45 {
            let gold = Int.random(in: 40...110)
            s.gold += gold
            s.treasuresFound += 1
            state = s
            present(ActionOutcome(title: "Fortune on the Road",
                                  message: "The journey rewards you with coin and small treasures.",
                                  deltas: ["+\(gold) Gold", "+1 Treasure"], tone: .good))
        } else if roll > 20 {
            state = s
            present(ActionOutcome(title: "A Quiet Journey",
                                  message: "The road is long and uneventful, but you return safely.",
                                  tone: .neutral))
        } else {
            // Bandit encounter.
            resolveCombat(name: "Desert Bandits", difficulty: 14, context: "on the road")
        }
    }

    private func doSearchDungeon() {
        guard var s = state else { return }

        // The easiest still-undiscovered dungeon is the one you might find.
        guard let target = undiscoveredDungeons.min(by: { $0.difficulty < $1.difficulty }) else {
            present(ActionOutcome(title: "Nothing Left to Find",
                                  message: "All known dungeons have already been discovered.",
                                  tone: .neutral))
            return
        }

        let roleBonus = (s.role == .wizardApprentice ? 8 : 0)
        let cluesInHand = s.pendingDungeonClues + (s.meta.blessing?.dungeonClueBonus ?? 0)
        let clueBonus = cluesInHand * 6
        let helpBonus = homeBonus(.dungeonSearch) * 3 + factionBonus(.magicians) + factionBonus(.djinnSpirits) + aliBabaCaveBonus
        let score = s.stats.luck + s.stats.wisdom + s.stats.magic + roleBonus + clueBonus + helpBonus + Int.random(in: 0...20)

        // Consume one clue per search if any.
        if s.pendingDungeonClues > 0 { s.pendingDungeonClues -= 1 }

        // Higher-level Djinn dungeons are far harder to locate and demand that
        // you already hold clues before the trail can even be found.
        let required = 45 + target.difficulty * 10
        let cluesNeeded = max(0, target.difficulty - 2)

        if score >= required && cluesInHand >= cluesNeeded {
            s.discoveredDungeons.append(target.id)
            s.pendingDungeonClues = 0     // discovering a dungeon consumes all clues
            state = s
            present(ActionOutcome(title: "A Dungeon Revealed!",
                                  message: "Your searching uncovers the entrance to \(target.name). Scheherazade's lore rings true.",
                                  deltas: ["Discovered \(target.name)", "Clues spent"], tone: .epic))
        } else if score > 25 {
            s.pendingDungeonClues += 1
            state = s
            let hint = cluesInHand < cluesNeeded
                ? "The trail to \(target.name) demands more clues than you hold."
                : "You find no entrance, but a clue toward one."
            present(ActionOutcome(title: "A Faint Trail",
                                  message: hint,
                                  deltas: ["+1 Dungeon Clue"], tone: .good))
        } else {
            state = s
            present(ActionOutcome(title: "Nothing but Sand",
                                  message: "The desert keeps its secrets tonight.",
                                  tone: .neutral))
        }
    }

    private func doPalace() {
        guard var s = state else { return }
        SoundManager.shared.play(.palace)
        // Guard & noble favor — and Jasmine's word at court — lower the honor
        // needed to enter.
        let requiredHonor = max(5, 15 - factionBonus(.guards) - factionBonus(.nobles) - jasmineEntryEase)
        if s.stats.honor < requiredHonor && !s.palaceUnlocked {
            present(ActionOutcome(title: "Turned Away",
                                  message: "The guards bar your path. You need at least \(requiredHonor) Honor or an invitation to enter Sinbad's palace.",
                                  tone: .bad))
            return
        }
        s.palaceUnlocked = true

        // The court is a living thing — each visit plays out differently.
        // Favor (honor + reputation) tilts the odds toward the finer outcomes;
        // Jasmine's loyalty and the Djinns of Beauty & Judgment help at court.
        let djinnCourt = (has(.maymunah) ? 8 : 0) + (has(.shamhurish) ? 8 : 0)
        let favor = s.stats.honor + s.stats.reputation + jasmineFavorBoost + djinnCourt
        var outcome = palaceOutcome(favor: favor, into: &s)
        // Jasmine's friendship earns you a little extra Honor at court.
        if jasminePalaceHonor > 0 && outcome.title != "Turned Away" {
            s.stats.honor += jasminePalaceHonor
            outcome.deltas.append("+\(jasminePalaceHonor) Honor (Jasmine)")
        }
        state = s
        present(outcome)
    }

    /// Rolls one of many possible palace outcomes and applies it to `s`.
    private func palaceOutcome(favor: Int, into s: inout GameState) -> ActionOutcome {
        var roll = Int.random(in: 0..<100)
        // Higher favor nudges the roll upward toward the better events.
        roll = min(99, roll + favor / 6)

        switch roll {
        case 90...99:
            // Audience with King Sinbad himself.
            let gold = Int.random(in: 80...160)
            s.gold += gold; s.stats.honor += 3
            bumpRelationship("sinbad", 3, in: &s)
            var deltas = ["+\(gold) Gold", statGainLabel(.honor, 3, in: s)]
            // Only announce the Palace Advisor the first time you meet him.
            if !s.connections.contains("Palace Advisor") {
                s.connections.append("Palace Advisor")
                deltas.append("New ally: Palace Advisor")
            }
            return ActionOutcome(title: "Audience with Sinbad",
                                 message: "King Sinbad, the legendary sailor-king, receives you and names you a friend of the court.",
                                 deltas: deltas, tone: .epic)
        case 80...89:
            // The king hints at a royal mission.
            s.pendingDungeonClues += 1; s.stats.honor += 1
            return ActionOutcome(title: "A Royal Summons",
                                 message: "A steward says the king has need of you — a mission awaits at the palace board.",
                                 deltas: ["+1 Honor", "+1 Dungeon Clue"], tone: .good)
        case 68...79:
            // A rare story of the court's secrets.
            let gold = Int.random(in: 40...90)
            s.gold += gold; s.stats.wisdom += 2
            return ActionOutcome(title: "Whispers in the Halls",
                                 message: "An old courtier shares a tale of the palace's hidden history. You learn much.",
                                 deltas: ["+\(gold) Gold", "+2 Wisdom"], tone: .epic)
        case 56...67:
            // Meet a noble — a new connection.
            let nobles = ["Lady Suha", "Vizier Ramel", "Prince Kalim", "Countess Dunya"]
            let name = nobles.filter { !s.connections.contains($0) }.randomElement()
            if let name { s.connections.append(name) }
            bumpFaction(.nobles, 2, in: &s)
            return ActionOutcome(title: "A Noble's Favor",
                                 message: "You charm a member of the court and win their goodwill.",
                                 deltas: name != nil ? ["New ally: \(name!)", "+Nobles favor"] : ["+Nobles favor"], tone: .good)
        case 44...55:
            // Unlock a faction event with the guards.
            bumpFaction(.guards, 3, in: &s); s.stats.honor += 1
            return ActionOutcome(title: "The Guard's Respect",
                                 message: "You share a drink with Sinbad's guards and earn their trust.",
                                 deltas: ["+1 Honor", "+Guards favor"], tone: .good)
        case 32...43:
            // Find a rumor.
            s.pendingDungeonClues += 1
            return ActionOutcome(title: "A Rumor at Court",
                                 message: "Between the marble columns you overhear talk of a sealed dungeon beyond the dunes.",
                                 deltas: ["+1 Dungeon Clue"], tone: .good)
        case 20...31:
            // Simply gain a little honor mingling.
            s.stats.honor += 1
            return ActionOutcome(title: "Among the Nobles",
                                 message: "You mingle in the palace halls and earn a measure of respect.",
                                 deltas: ["+1 Honor"], tone: .good)
        case 10...19:
            // Court politics cost you reputation.
            let loss = min(s.stats.reputation, Int.random(in: 2...4))
            s.stats.reputation -= loss
            return ActionOutcome(title: "Court Politics",
                                 message: "A rival whispers against you in the king's ear. Your standing suffers.",
                                 deltas: ["-\(loss) Reputation"], tone: .bad)
        default:
            // Turned away by suspicious guards.
            return ActionOutcome(title: "Turned Away",
                                 message: "The guards are wary tonight and send you back to the streets, empty-handed.",
                                 tone: .bad)
        }
    }

    private func doConnections() {
        guard var s = state else { return }
        let names = ["Old Merchant Faruq", "Guard Captain Layla", "The Magician Idris",
                     "Sailor Yusuf", "Healer Amina", "The Thief Rashid", "Storyteller Nadia"]
        let zeparBonus = has(.zepar) ? 3 : 0
        let maymunahBonus = has(.maymunah) ? 3 : 0   // Djinn of Beauty
        let rep = Int.random(in: 1...3) + zeparBonus + maymunahBonus
        s.stats.reputation += rep
        var deltas = ["+\(rep) Reputation"]
        if let name = names.filter({ !s.connections.contains($0) }).randomElement(),
           Int.random(in: 0...100) < 55 {
            s.connections.append(name)
            deltas.append("New ally: \(name)")
        }
        state = s
        SoundManager.shared.play(.door)
        present(ActionOutcome(title: "Building Bonds",
                              message: "You share tea and stories, weaving yourself into Zahara's web of favors.",
                              deltas: deltas, tone: .good))
    }

    private func doSearchTreasure() {
        guard var s = state else { return }
        let cunningBonus = s.role == .marketOrphan ? 6 : 0
        let treasureBonus = (s.meta.blessing?.treasureBonus ?? 0) + homeBonus(.treasure)
            + factionBonus(.thieves) + companionBonus(.treasure) + aliBabaTreasureBonus
        let score = s.stats.luck + s.stats.cunning + cunningBonus + treasureBonus + Int.random(in: 0...25)
        if score > 55 {
            let gold = Int.random(in: 80...180)
            s.gold += gold
            s.treasuresFound += 1
            // Occasionally a map that becomes a dungeon clue.
            var deltas = ["+\(gold) Gold", "+1 Treasure"]
            if Int.random(in: 0...100) < 30 {
                s.pendingDungeonClues += 1
                deltas.append("+1 Dungeon Clue")
            }
            // Sometimes a rare found item or crafting material. Aladdin's
            // friendship raises the chance of turning up something magical.
            if Int.random(in: 0...100) < 45 + aladdinMagicFindBonus {
                let findable = ItemCatalog.searchItems + CraftCatalog.materials
                if let found = findable.randomElement() {
                    let (_, extra) = grant(found, to: &s)
                    deltas.append(extra.isEmpty ? "Found \(found.name)" : extra[0])
                }
            }
            // Storage room turns up extra dust.
            if homeBonus(.dust) > 0 {
                s.meta.magicalDust += homeBonus(.dust)
                deltas.append("+\(homeBonus(.dust)) Dust")
            }
            state = s
            SoundManager.shared.play(.treasure)
            present(ActionOutcome(title: "Buried Fortune!",
                                  message: "Your instincts pay off — a cache of coin and curios.",
                                  deltas: deltas, tone: .epic))
        } else if score > 30 {
            let gold = Int.random(in: 20...50)
            s.gold += gold
            state = s
            present(ActionOutcome(title: "A Small Find",
                                  message: "You turn up a few loose coins in the market dust.",
                                  deltas: ["+\(gold) Gold"], tone: .good))
        } else {
            state = s
            present(ActionOutcome(title: "Empty-Handed",
                                  message: "You search high and low but find nothing of worth.",
                                  tone: .neutral))
        }
    }

    private func doRest() {
        guard var s = state else { return }
        // Rest always restores exactly 2 energy — no Djinn, item, room, artifact
        // or upgrade may increase this.
        let restore = 2
        s.energy = min(s.maxEnergy, s.energy + restore)
        var deltas = ["+\(restore) Energy"]
        // Rest also tends injuries.
        if s.meta.injuries > 0 {
            s.meta.injuries -= 1
            deltas.append("An injury mends")
        }
        state = s
        restedThisNight = true      // Rest is limited to once per night.
        present(ActionOutcome(title: "Rest",
                              message: "You breathe, recover, and perhaps dream a prophetic dream.",
                              deltas: deltas, tone: .good))
    }

    // MARK: - Combat (used by journeys and events)

    private func resolveCombat(name: String, difficulty: Int, context: String) {
        guard var s = state else { return }
        var power = s.stats.courage + s.stats.endurance + s.stats.magic / 2
        if has(.barbatos) { power += 6 }
        if has(.baal)     { power += 4 }
        if has(.ifrit)    { power += 7 }   // Djinn of War
        if has(.shiqq)    { power += 3 }   // fear cows the enemy
        if has(.barqan)   { power += 3 }   // opening lightning
        if has(.dasim)    { power += 3 }   // sows discord among foes
        // The King of the Djinns empowers every bond you hold.
        if KingOfDjinns.isBonded(s) { power += s.djinns.count }
        power += s.stats.speed / 3      // Speed lets you strike first
        power += (s.meta.blessing?.combatBonus ?? 0) + companionBonus(.combat)
        // Difficulty scales gently with the night number.
        let scaledDifficulty = difficulty + s.night / 12
        let won = check(power, difficulty: scaledDifficulty, luck: s.stats.luck)
        if won {
            let gold = Int.random(in: 30...80)
            s.gold += gold
            s.stats.courage += 1
            state = s
            present(ActionOutcome(title: "Victory!",
                                  message: "You defeat the \(name) \(context) and claim the spoils.",
                                  deltas: ["+\(gold) Gold", "+1 Courage"], tone: .good))
        } else {
            // A quick hero can escape the worst of a lost fight.
            let escaped = check(s.stats.speed, difficulty: 13)
            var damage = Int.random(in: 2...4)
            if has(.phenex) { damage = max(1, damage - 1) }
            if escaped { damage = max(1, damage - 2) }
            s.stats.endurance = max(0, s.stats.endurance - damage)
            let goldLoss = min(s.gold, Int.random(in: 10...40))
            s.gold -= goldLoss
            var deltas = ["-\(damage) Endurance", "-\(goldLoss) Gold"]
            if escaped {
                deltas.append("Escaped unhurt")
            } else {
                s.meta.injuries += 1
                deltas.append("Injured")
            }
            state = s
            present(ActionOutcome(title: escaped ? "A Narrow Escape" : "Wounded",
                                  message: escaped
                                    ? "The \(name) get the better of you \(context), but your quickness saves you from lasting harm."
                                    : "The \(name) get the better of you \(context). You flee, battered.",
                                  deltas: deltas, tone: .bad))
        }
    }

    // MARK: - Shop / items / upgrades

    /// True if the item is a unique (non-consumable) one the player already holds.
    func alreadyOwnsUnique(_ item: Item) -> Bool {
        !item.consumable && (state?.inventory[item.id] ?? 0) > 0
    }

    /// Buy an item. Returns a short feedback message and does NOT open a global
    /// sheet, so the shop stays open after each purchase.
    @discardableResult
    func buy(_ item: Item) -> String {
        guard var s = state else { return "" }
        // Can't buy a duplicate of a unique item already in the pack.
        if alreadyOwnsUnique(item) {
            return "You already own \(item.name)."
        }
        let price = shopPrice(item, in: s)
        guard s.gold >= price else {
            return "You can't afford \(item.name) (\(price) gold)."
        }
        s.gold -= price
        let (msg, extra) = grant(item, to: &s)
        state = s
        HapticManager.play(.success)
        addJournal("Bought \(item.name).")
        nightEntries.append(NightSummary.Entry(title: "Purchased \(item.name)",
                                               deltas: ["-\(price) Gold"] + extra, tone: "good"))
        save()
        return "\(msg) (−\(price) gold)"
    }

    /// Uses a consumable from the inventory (e.g. food, keys, maps).
    func useItem(_ item: Item) {
        guard var s = state, (s.inventory[item.id] ?? 0) > 0 else { return }
        s.inventory[item.id]! -= 1
        if s.inventory[item.id]! <= 0 { s.inventory[item.id] = nil }
        applyEffect(item.effect, to: &s)
        state = s
        present(ActionOutcome(title: "Used \(item.name)", message: item.detail, tone: .good))
    }

    func applyEffect(_ effect: ItemEffect, to s: inout GameState) {
        switch effect {
        case .restoreEnergy(let n):
            s.energy = min(s.maxEnergy, s.energy + n)
        case .grantStat(let kind, let n):
            s.stats[kind] += n
        case .luckCharm(let n):
            s.stats.luck += n
        case .dungeonKey:
            s.pendingDungeonClues += 2
        case .treasureMap:
            // Reveal the easiest undiscovered dungeon.
            if let found = DungeonCatalog.all
                .filter({ !s.discoveredDungeons.contains($0.id) && !s.completedDungeons.contains($0.id) })
                .min(by: { $0.difficulty < $1.difficulty }) {
                s.discoveredDungeons.append(found.id)
                s.pendingDungeonClues = 0     // a discovery consumes all clues
            }
        case .healInjury(let n):
            s.meta.injuries = max(0, s.meta.injuries - n)
        case .none:
            break
        }
    }

    /// Cost in gold to raise a stat by one point (Ugo gives a discount).
    func upgradeCost(for kind: StatKind) -> Int {
        guard let s = state else { return 999 }
        let base = 20 + s.stats[kind] * 3
        return has(.ugo) ? Int(Double(base) * 0.8) : base
    }

    /// Each upgrade costs 2 energy plus gold.
    static let upgradeEnergyCost = 2

    /// A stat that has reached the cap can no longer be improved.
    func isStatMaxed(_ kind: StatKind) -> Bool {
        (state?.stats[kind] ?? 0) >= Stats.cap
    }

    func canUpgrade(_ kind: StatKind) -> Bool {
        guard let s = state, !isStatMaxed(kind) else { return false }
        return s.energy >= GameViewModel.upgradeEnergyCost && s.gold >= upgradeCost(for: kind)
    }

    func upgrade(_ kind: StatKind) {
        guard var s = state else { return }
        let cost = upgradeCost(for: kind)
        guard s.energy >= GameViewModel.upgradeEnergyCost else {
            outcome = ActionOutcome(title: "Too Tired",
                                    message: "Improving a stat costs \(GameViewModel.upgradeEnergyCost) energy.", tone: .bad)
            return
        }
        guard s.gold >= cost else {
            outcome = ActionOutcome(title: "Not Enough Gold",
                                    message: "You need \(cost) gold to improve \(kind.title).", tone: .bad)
            return
        }
        s.energy -= GameViewModel.upgradeEnergyCost
        s.gold -= cost
        s.stats[kind] += 1
        state = s
        present(ActionOutcome(title: "\(kind.title) Improved",
                              message: "Through effort and coin, you grow stronger.",
                              deltas: ["+1 \(kind.title)", "-\(cost) Gold", "-\(GameViewModel.upgradeEnergyCost) Energy"], tone: .good))
    }

    // MARK: - Dungeons

    var discoveredDungeons: [Dungeon] {
        guard let s = state else { return [] }
        var list = DungeonCatalog.all.filter { s.discoveredDungeons.contains($0.id) }
        // Al-Mudhib's throne lives outside the ordinary catalog.
        if s.discoveredDungeons.contains(KingOfDjinns.throneID) {
            list.append(KingOfDjinns.throneDungeon)
        }
        return list
    }

    /// Dungeons neither discovered nor already conquered — the pool a search can reveal.
    var undiscoveredDungeons: [Dungeon] {
        guard let s = state else { return [] }
        return DungeonCatalog.all.filter {
            !s.discoveredDungeons.contains($0.id) && !s.completedDungeons.contains($0.id)
        }
    }

    /// True when there is nothing left to discover.
    var allDungeonsDiscovered: Bool { state != nil && undiscoveredDungeons.isEmpty }

    /// Rest may be taken only once per night.
    var canRest: Bool {
        guard let s = state else { return false }
        return !restedThisNight && s.energy >= NightAction.rest.energyCost
    }

    func isCompleted(_ dungeon: Dungeon) -> Bool {
        state?.completedDungeons.contains(dungeon.id) ?? false
    }

    func enterDungeon(_ dungeon: Dungeon) {
        let cost = dungeon.entryEnergyCost
        guard var s = state, s.energy >= cost else {
            outcome = ActionOutcome(title: "Too Tired",
                                    message: "Entering \(dungeon.name) costs \(dungeon.entryEnergyCost) energy. Rest first.", tone: .bad)
            return
        }
        s.energy -= cost
        state = s
        save()
        AudioManager.shared.setMood(.dungeon)
        // Scale room difficulty with the night number, and stiffen dungeons
        // that are above Hard (difficulty > 3).
        let nightBump = s.night / 10
        let hardBump = dungeon.difficulty > 3 ? (dungeon.difficulty - 3) * 2 : 0
        let totalBump = nightBump + hardBump
        var scaled = dungeon
        if totalBump > 0 {
            scaled.rooms = dungeon.rooms.map { room in
                var r = room
                r.difficulty += totalBump
                return r
            }
        }
        activeRun = DungeonRun(dungeon: scaled,
                               log: ["You step into \(dungeon.name). The air is thick with old magic."])
    }

    /// Percentage chance to clear a room, from the player's stat difference
    /// against the room's requirement.
    func successChance(statValue: Int, requirement: Int) -> Int {
        switch statValue - requirement {
        case ..<(-20):       return 8
        case (-20) ..< (-10): return 15
        case (-10) ..< 0:    return 33
        case 0 ..< 10:       return 50
        case 10 ..< 20:      return 65
        case 20 ..< 40:      return 75
        default:             return 85
        }
    }

    /// Resolve the current room and advance, or end the run on failure.
    func resolveCurrentRoom() {
        guard var run = activeRun, var s = state, let room = run.currentRoom else { return }

        var testValue = s.stats[room.kind.testedStat]
        // Djinn aids for specific room types.
        if room.kind == .puzzle, has(.dantalion) { testValue += 5 }
        if (room.kind == .monster || room.kind == .boss), has(.amon) { testValue += 4 }
        if room.kind == .djinnChamber, has(.baal) { testValue += 3 }
        testValue += s.stats.luck / 6      // luck still nudges the odds

        // Percentage chance based on how far your stat sits from the room's
        // requirement (see `successChance`).
        let chance = successChance(statValue: testValue, requirement: room.difficulty)
        let success = Int.random(in: 0..<100) < chance

        if success {
            run.log.insert("✔ \(room.name): you prevail. (\(room.kind.testedStat.title) held firm)", at: 0)
            if room.kind == .treasure {
                let gold = Int.random(in: 40...100)
                s.gold += gold
                s.treasuresFound += 1
                run.log.insert("   You loot \(gold) gold from the hoard.", at: 0)
            }
            // Monsters may drop crafting materials.
            if (room.kind == .monster || room.kind == .boss), Int.random(in: 0...100) < 50 {
                let matID = CraftCatalog.randomMaterialID()
                s.inventory[matID, default: 0] += 1
                run.log.insert("   You gather \(ItemCatalog.item(id: matID)?.name ?? "material").", at: 0)
            }
            run.roomIndex += 1
            if run.roomIndex >= run.dungeon.rooms.count {
                run.finished = true
                run.conquered = true
                run.log.insert("You have conquered \(run.dungeon.name)!", at: 0)
            }
        } else {
            // Take a wound; the run may end if endurance breaks.
            var damage = Int.random(in: 2...4)
            if has(.phenex) { damage = max(1, damage - 1) }
            damage = max(1, damage - companionBonus(.dungeonSafety) / 3)   // companions soften blows
            damage = max(1, damage - aladdinDungeonSafety)                 // Aladdin knows the traps
            s.stats.endurance = max(0, s.stats.endurance - damage)
            s.meta.injuries += 1
            run.log.insert("✘ \(room.name): the challenge wounds you. -\(damage) Endurance.", at: 0)
            if s.stats.endurance <= 3 {
                run.finished = true
                run.conquered = false
                run.log.insert("Too wounded to go on, you retreat from \(run.dungeon.name).", at: 0)
                // Losing a dungeon loses its location — it must be discovered anew.
                s.discoveredDungeons.removeAll { $0 == run.dungeon.id }
                run.log.insert("The path caves in behind you. \(run.dungeon.name) is lost to the sands — you must find it again.", at: 0)
            }
        }
        state = s
        activeRun = run
        save()
    }

    /// Claim the Djinn / rewards after conquering, then close the run.
    func claimDungeonReward() {
        guard var run = activeRun, var s = state, run.conquered, !run.rewardClaimed else {
            activeRun = nil
            return
        }
        run.rewardClaimed = true
        s.gold += run.dungeon.goldReward
        if !s.completedDungeons.contains(run.dungeon.id) {
            s.completedDungeons.append(run.dungeon.id)
        }
        var deltas = ["+\(run.dungeon.goldReward) Gold"]
        if let djinn = run.dungeon.djinnReward {
            if !s.djinns.contains(djinn) {
                s.djinns.append(djinn)
                s.stats = s.stats + djinn.statBonus
                deltas.append("Bonded with \(djinn.name)!")
            }
            // Award the Djinn's magical artifact.
            let artifact = ArtifactCatalog.artifact(for: djinn)
            if !s.meta.artifacts.contains(artifact.id) {
                s.meta.artifacts.append(artifact.id)
                let (_, extra) = grant(artifact, to: &s)
                deltas.append("Artifact: \(artifact.name)")
                deltas += extra
            }
            bumpRelationship("scheherazade", 3, in: &s)
            bumpRelationship("aladdin", 3, in: &s)      // he lives for Djinn artifacts
            bumpFaction(.djinnSpirits, 5, in: &s)
        }
        // Al-Mudhib's throne: the King's crown, and a sovereign's blessing.
        if run.dungeon.id == KingOfDjinns.throneID {
            if !s.meta.artifacts.contains(KingOfDjinns.artifactID) {
                s.meta.artifacts.append(KingOfDjinns.artifactID)
                let (_, extra) = grant(KingOfDjinns.artifact, to: &s)
                deltas.append("Artifact: \(KingOfDjinns.artifact.name)")
                deltas += extra
            }
            s.stats.magic += 10
            s.stats.wisdom += 8
            deltas.append("+10 Magic, +8 Wisdom — the King's blessing")
            bumpRelationship("scheherazade", 5, in: &s)
            bumpRelationship("sinbad", 5, in: &s)
            bumpFaction(.djinnSpirits, 15, in: &s)
        }
        // A chance at a piece of dungeon gear.
        if let gear = ItemCatalog.dungeonGear.randomElement(), Int.random(in: 0...100) < 60 {
            let (_, extra) = grant(gear, to: &s)
            deltas += extra.isEmpty ? ["Found \(gear.name)"] : extra
        }
        // Magical dust and a crafting material from the hoard.
        s.meta.magicalDust += Int.random(in: 2...5)
        let matID = CraftCatalog.randomMaterialID()
        s.inventory[matID, default: 0] += 1
        deltas.append("Material: \(ItemCatalog.item(id: matID)?.name ?? matID)")
        state = s
        activeRun = nil
        AudioManager.shared.setMood(.victory)
        present(ActionOutcome(title: "Dungeon Conquered",
                              message: "You emerge from \(run.dungeon.name) a legend richer.",
                              deltas: deltas, tone: .epic))
    }

    func retreatDungeon() {
        // Retreating from an unconquered dungeon loses its location; you must
        // search for and discover it again before another attempt.
        if let run = activeRun, !run.conquered, var s = state {
            s.discoveredDungeons.removeAll { $0 == run.dungeon.id }
            state = s
        }
        activeRun = nil
        save()
    }

    // MARK: - In-dungeon Djinn abilities

    /// Whether the player owns a given Djinn (public for the dungeon UI).
    func owns(_ djinn: Djinn) -> Bool { has(djinn) }

    /// Room kinds a Djinn's signature ability can overcome outright.
    private func abilityTargets(_ djinn: Djinn) -> Set<RoomKind> {
        switch djinn {
        case .amon:      return [.monster, .boss, .trap]        // Amon's Flame
        case .dantalion: return [.puzzle, .trap, .djinnChamber] // Light of Truth
        case .baal:      return Set(RoomKind.allCases)          // Lightning Strike — anything
        case .vinea:     return [.trap, .puzzle]                // Hidden Current
        // Additional Djinns.
        case .shiqq:     return [.monster, .boss]               // Terror Gaze
        case .nasnas:    return [.trap, .monster]               // Blink Step
        case .ifrit:     return [.monster, .boss]               // Warflame Command
        case .khanzan:   return [.trap, .puzzle, .djinnChamber] // Sacred Focus
        case .barqan:    return [.monster, .boss]               // Thunder Strike
        case .maymunah:  return [.puzzle, .djinnChamber]        // Radiant Charm
        case .danhash:   return [.treasure, .puzzle]            // Joyful Omen
        case .zalmbur:   return [.treasure]                     // Golden Bargain
        case .sut:       return [.trap, .puzzle]                // False Mask
        case .dasim:     return [.monster, .boss]               // Spark of Discord
        case .zawbaah:   return [.trap, .monster]               // Eye of the Storm
        case .shamhurish:return [.puzzle, .djinnChamber]        // Verdict of Truth
        default:         return []
        }
    }

    /// Djinns whose ability can be invoked on the current room right now.
    func usableAbilities() -> [Djinn] {
        guard let run = activeRun, let room = run.currentRoom, !run.finished else { return [] }
        return Djinn.allCases.filter { djinn in
            has(djinn)
            && !run.abilitiesUsed.contains(djinn.rawValue)
            && abilityTargets(djinn).contains(room.kind)
        }
    }

    /// Invoke a Djinn's ability to clear the current room without a check.
    func useAbility(_ djinn: Djinn) {
        guard var run = activeRun, let room = run.currentRoom, !run.finished,
              has(djinn), !run.abilitiesUsed.contains(djinn.rawValue) else { return }
        run.abilitiesUsed.insert(djinn.rawValue)
        run.log.insert("✨ \(djinn.abilityName): \(room.name) is overcome without a scratch!", at: 0)
        run.roomIndex += 1
        if run.roomIndex >= run.dungeon.rooms.count {
            run.finished = true
            run.conquered = true
            run.log.insert("You have conquered \(run.dungeon.name)!", at: 0)
        }
        activeRun = run
        save()
    }

    // MARK: - Palace / royal missions

    var activeQuest: PalaceQuest? {
        guard let id = state?.activeQuestID else { return nil }
        return QuestCatalog.quest(id: id)
    }

    /// Quests Sinbad can offer: not completed, not active, not already trivially met.
    func availableQuests() -> [PalaceQuest] {
        guard let s = state else { return [] }
        return QuestCatalog.all.filter {
            $0.id != s.activeQuestID
            && !s.completedQuestIDs.contains($0.id)
            && !$0.objective.isSatisfied(in: s)
        }
    }

    var isActiveQuestComplete: Bool {
        guard let s = state, let quest = activeQuest else { return false }
        return quest.objective.isSatisfied(in: s)
    }

    func acceptQuest(_ quest: PalaceQuest) {
        guard var s = state, s.activeQuestID == nil else { return }
        s.activeQuestID = quest.id
        state = s
        present(ActionOutcome(title: "Mission Accepted",
                              message: "King Sinbad entrusts you with \"\(quest.title)\".",
                              deltas: [quest.objective.label], tone: .neutral))
    }

    func claimActiveQuest() {
        guard var s = state, let quest = activeQuest, isActiveQuestComplete else { return }
        s.gold += quest.rewardGold
        s.stats.honor += quest.rewardHonor
        s.stats.reputation += quest.rewardReputation
        s.completedQuestIDs.append(quest.id)
        s.activeQuestID = nil
        s.palaceUnlocked = true
        state = s
        var deltas: [String] = []
        if quest.rewardGold > 0 { deltas.append("+\(quest.rewardGold) Gold") }
        if quest.rewardHonor > 0 { deltas.append("+\(quest.rewardHonor) Honor") }
        if quest.rewardReputation > 0 { deltas.append("+\(quest.rewardReputation) Reputation") }
        present(ActionOutcome(title: "Mission Complete",
                              message: "King Sinbad rewards your service. \"You honor Zahara,\" he declares.",
                              deltas: deltas, tone: .epic))
    }

    func seekAudience() {
        _ = perform(.palace)
    }

    /// The King's Court of Justice — a different purpose from a palace audience.
    /// Like the palace it needs Reputation/Honor, but here you preside over law
    /// and truth rather than court politics.
    func attendCourt() {
        guard var s = state else { return }
        guard s.energy >= 2 else {
            outcome = ActionOutcome(title: "Too Tired",
                                    message: "Attending the court costs 2 energy.", tone: .bad)
            return
        }
        let requiredHonor = max(5, 15 - factionBonus(.guards) - factionBonus(.nobles) - jasmineEntryEase)
        if s.stats.honor < requiredHonor && !s.palaceUnlocked {
            present(ActionOutcome(title: "Barred from the Court",
                                  message: "The magistrates turn you away. You need at least \(requiredHonor) Honor to sit in judgment.",
                                  tone: .bad))
            return
        }
        s.energy -= 2
        state = s
        doCourt()
        creditFactions(for: .palace)
        creditCharacters(for: .palace)
    }

    private func doCourt() {
        guard var s = state else { return }
        s.palaceUnlocked = true
        // Shamhurish, Djinn of Judgment, all but guarantees a just verdict.
        let roll = has(.shamhurish) ? 100 : (Int.random(in: 0..<100) + (s.stats.wisdom + s.stats.honor) / 8)
        if roll > 66 {
            let gold = Int.random(in: 40...90)
            s.gold += gold; s.stats.honor += 2; s.stats.reputation += 2
            state = s
            present(ActionOutcome(title: "A Just Verdict",
                                  message: "You weigh the evidence and deliver a fair judgment. Zahara respects a wise arbiter.",
                                  deltas: ["+\(gold) Gold", statGainLabel(.honor, 2, in: s), statGainLabel(.reputation, 2, in: s)], tone: .good))
        } else if roll > 30 {
            s.stats.wisdom += 2
            state = s
            present(ActionOutcome(title: "Hearing the Cases",
                                  message: "You sit among the magistrates and study the law of Zahara.",
                                  deltas: [statGainLabel(.wisdom, 2, in: s)], tone: .good))
        } else {
            let repLoss = min(s.stats.reputation, Int.random(in: 1...3))
            s.stats.reputation -= repLoss
            s.stats.honor += 1
            state = s
            present(ActionOutcome(title: "A Bribe Refused",
                                  message: "A merchant offers coin to sway your ruling. You refuse — but he spreads spiteful rumors.",
                                  deltas: ["-\(repLoss) Reputation", statGainLabel(.honor, 1, in: s)], tone: .neutral))
        }
    }

    // MARK: - Night flow

    func endNight() {
        guard var s = state else { return }
        let endingNight = s.night
        let titleBefore = TitleSystem.currentTitle(for: s)

        // Passive Djinn blessings applied at the turn of the night.
        if has(.ugo) { s.gold += 5 }
        if has(.zagan) && Int.random(in: 0...100) < 20 { s.stats.luck += 1 }

        // Build the summary for the night that just ended.
        var summary = NightSummary(nightNumber: endingNight, nextNight: endingNight + 1)
        summary.entries = nightEntries
        summary.goldChange = s.gold - nightStartGold
        summary.injuriesGained = max(0, s.meta.injuries - nightStartInjuries)
        summary.events = nightEventLines
        summary.statChanges = StatKind.allCases.compactMap { kind in
            let d = s.stats[kind] - nightStartStats[kind]
            return d != 0 ? "\(kind.title) \(d > 0 ? "+" : "")\(d)" : nil
        }
        if let b = s.meta.blessing { summary.events.append("\(b.name)") }

        s.night += 1
        // The game no longer ends automatically — the player decides whether to
        // continue or finish at each 100-night checkpoint (see below).

        // Injuries slowly recover on their own by one at night's turn.
        if s.meta.injuries > 0 && Int.random(in: 0...100) < 40 { s.meta.injuries -= 1 }

        // Roll a new blessing/curse for the coming night.
        let newMod = BlessingCatalog.roll(luckAffinity: s.stats.luck)
        s.meta.blessing = newMod
        if let mod = newMod {
            summary.tonightBlessing = mod.name
        }

        // Scale and restore energy for the new era, plus the Resting Room's
        // bonus to maximum energy, reduced by lingering injuries.
        s.maxEnergy = s.energyForCurrentEra + (newMod?.energyDelta ?? 0) + homeBonus(.maxEnergy)
        s.energy = max(3, s.maxEnergy - s.meta.injuries)

        // Title advancement note.
        let titleAfter = TitleSystem.currentTitle(for: s)
        if titleAfter != titleBefore { summary.newTitle = titleAfter }

        // Milestone every 10 nights (folded into the summary, no extra sheet).
        if s.night % 10 == 0 {
            if let (line, deltas) = applyMilestone(&s) {
                summary.events.append(line)
                summary.entries.append(NightSummary.Entry(title: "Milestone — Night \(s.night)",
                                                          deltas: deltas, tone: "epic"))
            }
        }

        // The Throne of the Hidden Flame reveals itself once the King's
        // conditions are met — a once-only, dramatic discovery.
        if KingOfDjinns.isUnlocked(s),
           !s.discoveredDungeons.contains(KingOfDjinns.throneID),
           !s.completedDungeons.contains(KingOfDjinns.throneID) {
            s.discoveredDungeons.append(KingOfDjinns.throneID)
            let line = "A pillar of hidden flame rises beyond Zahara. Scheherazade whispers: \"The Throne of Al-Mudhib, King of the Djinns, has judged you worthy to find it.\""
            summary.events.append(line)
            summary.entries.append(NightSummary.Entry(title: "The King's Summons",
                                                      deltas: ["Throne of the Hidden Flame revealed"], tone: "epic"))
            noteInJournal(&s, "The Throne of the Hidden Flame has appeared. Al-Mudhib awaits.")
        }

        s.meta.lastSummary = summary
        state = s

        // Every 100 nights (the night that just ended), show the grand
        // retrospective with Continue / Finish choices instead of a normal
        // nightly summary and event.
        if endingNight % GameState.totalNights == 0 {
            bufferedEvent = nil
            journeyCheckpointNight = endingNight
        } else {
            // Present the summary popup first…
            nightSummary = summary
            // …then queue an event to fire once the summary is dismissed.
            // Priority: story choice > character encounter > rare event > ordinary.
            bufferedEvent = StoryChoices.pending(for: s)
                ?? CharacterEvents.maybeTrigger(for: s)
                ?? RareEvents.maybeTrigger(for: s)
                ?? RandomEvents.maybeTrigger(for: s)
        }

        beginNightTracking()
        AudioManager.shared.setMood(.city)
        save()
    }

    /// Continue playing beyond a 100-night checkpoint.
    func continueJourney() {
        journeyCheckpointNight = nil
    }

    /// End the journey for good at a checkpoint — go to the final legend.
    func finishJourney() {
        guard var s = state else { return }
        s.meta.journeyFinished = true
        state = s
        journeyCheckpointNight = nil
        phase = .ended
        save()
    }

    /// Called when the night-summary sheet is dismissed, to surface any queued event.
    func flushBufferedEvent() {
        if let e = bufferedEvent {
            bufferedEvent = nil
            pendingEvent = e
        }
    }

    func resolve(_ event: GameEvent, choosing option: EventOption) {
        guard var s = state else { return }
        let result = option.apply(&s)
        state = s
        pendingEvent = nil
        addJournal(result)
        nightEventLines.append("\(event.title): \(result)")
        outcome = ActionOutcome(title: event.title, message: result, tone: .neutral)
        save()
    }

    func dismissEvent() {
        pendingEvent = nil
    }
}
