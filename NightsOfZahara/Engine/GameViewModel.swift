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
    /// An event queued to appear after the night-summary sheet is dismissed.
    var bufferedEvent: GameEvent?

    // Transient night-summary tracking (reset each night)
    var nightStartGold = 0
    var nightStartStats: Stats = .zero
    var nightStartInjuries = 0
    var nightEntries: [NightSummary.Entry] = []
    var nightEventLines: [String] = []

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
        guard let state else { return }
        SaveManager.save(state)
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

        // Paimon lets journeys cost less.
        var cost = action.energyCost
        if action == .journey, has(.paimon) { cost = max(1, cost - 1) }

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
        case .journey:        doJourney()
        case .searchDungeon:  doSearchDungeon()
        case .palace:         doPalace()
        case .connections:    doConnections()
        case .searchTreasure: doSearchTreasure()
        case .rest:           doRest()
        case .shop, .upgrade, .eat: break
        }
        creditFactions(for: action)
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
        s.gold += gold
        s.stats.reputation += rep
        state = s
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
        var deltas = ["+\(wis) Wisdom"]
        if mag > 0 { deltas.append("+\(mag) Magic") }
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
                              deltas: ["+\(cour) Courage", "+\(end) Endurance"],
                              tone: .good))
    }

    private func doJourney() {
        guard var s = state else { return }
        let luckMod = (s.role == .sailor ? 6 : 0) + factionBonus(.sailors) * 2
        let roll = Int.random(in: 0...100) + (s.stats.luck + luckMod) / 3
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
        let roleBonus = (s.role == .wizardApprentice ? 8 : 0)
        let clueBonus = (s.pendingDungeonClues + (s.meta.blessing?.dungeonClueBonus ?? 0)) * 6
        let helpBonus = homeBonus(.dungeonSearch) * 3 + factionBonus(.magicians) + factionBonus(.djinnSpirits)
        let score = s.stats.luck + s.stats.wisdom + s.stats.magic + roleBonus + clueBonus + helpBonus + Int.random(in: 0...20)

        // Consume one clue per search if any.
        if s.pendingDungeonClues > 0 { s.pendingDungeonClues -= 1 }

        // Which dungeons are still undiscovered?
        let undiscovered = DungeonCatalog.all.filter { !s.discoveredDungeons.contains($0.id) }

        if score > 45, let found = undiscovered.min(by: { $0.difficulty < $1.difficulty }) {
            s.discoveredDungeons.append(found.id)
            state = s
            present(ActionOutcome(title: "A Dungeon Revealed!",
                                  message: "Your searching uncovers the entrance to \(found.name). Scheherazade's lore rings true.",
                                  deltas: ["Discovered \(found.name)"], tone: .epic))
        } else if score > 25 {
            s.pendingDungeonClues += 1
            state = s
            present(ActionOutcome(title: "A Faint Trail",
                                  message: "You find no entrance, but a clue toward one.",
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
        // Guard & noble favor lowers the honor needed to enter.
        let requiredHonor = max(5, 15 - factionBonus(.guards) - factionBonus(.nobles))
        if s.stats.honor < requiredHonor && !s.palaceUnlocked {
            present(ActionOutcome(title: "Turned Away",
                                  message: "The guards bar your path. You need at least \(requiredHonor) Honor or an invitation to enter Sinbad's palace.",
                                  tone: .bad))
            return
        }
        s.palaceUnlocked = true
        let roll = s.stats.honor + s.stats.reputation + Int.random(in: 0...15)
        if roll > 40 {
            let gold = Int.random(in: 60...140)
            s.gold += gold
            s.stats.honor += 3
            if !s.connections.contains("Palace Advisor") { s.connections.append("Palace Advisor") }
            state = s
            present(ActionOutcome(title: "Audience with Sinbad",
                                  message: "King Sinbad, the legendary sailor-king, rewards your service and names you a friend of the court.",
                                  deltas: ["+\(gold) Gold", "+3 Honor", "New ally: Palace Advisor"], tone: .epic))
        } else {
            s.stats.honor += 1
            state = s
            present(ActionOutcome(title: "Among the Nobles",
                                  message: "You mingle in the palace halls and earn a measure of respect.",
                                  deltas: ["+1 Honor"], tone: .good))
        }
    }

    private func doConnections() {
        guard var s = state else { return }
        let names = ["Old Merchant Faruq", "Guard Captain Layla", "The Magician Idris",
                     "Sailor Yusuf", "Healer Amina", "The Thief Rashid", "Storyteller Nadia"]
        let zeparBonus = has(.zepar) ? 3 : 0
        let rep = Int.random(in: 1...3) + zeparBonus
        s.stats.reputation += rep
        var deltas = ["+\(rep) Reputation"]
        if let name = names.filter({ !s.connections.contains($0) }).randomElement(),
           Int.random(in: 0...100) < 55 {
            s.connections.append(name)
            deltas.append("New ally: \(name)")
        }
        state = s
        present(ActionOutcome(title: "Building Bonds",
                              message: "You share tea and stories, weaving yourself into Zahara's web of favors.",
                              deltas: deltas, tone: .good))
    }

    private func doSearchTreasure() {
        guard var s = state else { return }
        let cunningBonus = s.role == .marketOrphan ? 6 : 0
        let treasureBonus = (s.meta.blessing?.treasureBonus ?? 0) + homeBonus(.treasure)
            + factionBonus(.thieves) + companionBonus(.treasure)
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
            // Sometimes a rare found item or crafting material.
            if Int.random(in: 0...100) < 45 {
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
        var restore = 2
        if has(.phenex) { restore += 1 }
        restore += (s.meta.blessing?.restBonus ?? 0) + homeBonus(.rest)
        s.energy = min(s.maxEnergy, s.energy + restore)
        var deltas = ["+\(restore) Energy"]
        // Rest also tends injuries.
        if s.meta.injuries > 0 {
            s.meta.injuries -= 1
            deltas.append("An injury mends")
        }
        state = s
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
        power += (s.meta.blessing?.combatBonus ?? 0) + companionBonus(.combat)
        // Difficulty scales gently with the night number.
        let scaledDifficulty = difficulty + s.night / 120
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
            let loss = Int.random(in: 2...4)
            var damage = loss
            if has(.phenex) { damage = max(1, damage - 1) }
            s.stats.endurance = max(0, s.stats.endurance - damage)
            let goldLoss = min(s.gold, Int.random(in: 10...40))
            s.gold -= goldLoss
            s.meta.injuries += 1
            state = s
            present(ActionOutcome(title: "Wounded",
                                  message: "The \(name) get the better of you \(context). You flee, battered.",
                                  deltas: ["-\(damage) Endurance", "-\(goldLoss) Gold", "Injured"], tone: .bad))
        }
    }

    // MARK: - Shop / items / upgrades

    func buy(_ item: Item) {
        guard var s = state else { return }
        let price = shopPrice(item, in: s)
        guard s.gold >= price else {
            outcome = ActionOutcome(title: "Not Enough Gold",
                                    message: "You cannot afford \(item.name).", tone: .bad)
            return
        }
        s.gold -= price
        let (msg, extra) = grant(item, to: &s)
        state = s
        present(ActionOutcome(title: "Purchased", message: msg,
                              deltas: ["-\(price) Gold"] + extra, tone: .good))
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
                .filter({ !s.discoveredDungeons.contains($0.id) })
                .min(by: { $0.difficulty < $1.difficulty }) {
                s.discoveredDungeons.append(found.id)
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

    func canUpgrade(_ kind: StatKind) -> Bool {
        guard let s = state else { return false }
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
        return DungeonCatalog.all.filter { s.discoveredDungeons.contains($0.id) }
    }

    func isCompleted(_ dungeon: Dungeon) -> Bool {
        state?.completedDungeons.contains(dungeon.id) ?? false
    }

    func enterDungeon(_ dungeon: Dungeon) {
        guard var s = state, s.energy >= 4 else {
            outcome = ActionOutcome(title: "Too Tired",
                                    message: "Entering a dungeon costs 4 energy. Rest first.", tone: .bad)
            return
        }
        s.energy -= 4
        state = s
        save()
        AudioManager.shared.setMood(.dungeon)
        // Scale room difficulty gently with the night number.
        var scaled = dungeon
        let bump = s.night / 100
        if bump > 0 {
            scaled.rooms = dungeon.rooms.map { room in
                var r = room
                r.difficulty += bump
                return r
            }
        }
        activeRun = DungeonRun(dungeon: scaled,
                               log: ["You step into \(dungeon.name). The air is thick with old magic."])
    }

    /// Resolve the current room and advance, or end the run on failure.
    func resolveCurrentRoom() {
        guard var run = activeRun, var s = state, let room = run.currentRoom else { return }

        var testValue = s.stats[room.kind.testedStat]
        // Djinn aids for specific room types.
        if room.kind == .puzzle, has(.dantalion) { testValue += 5 }
        if (room.kind == .monster || room.kind == .boss), has(.amon) { testValue += 4 }
        if room.kind == .djinnChamber, has(.baal) { testValue += 3 }

        let success = check(testValue, difficulty: room.difficulty, luck: s.stats.luck)

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
            s.stats.endurance = max(0, s.stats.endurance - damage)
            s.meta.injuries += 1
            run.log.insert("✘ \(room.name): the challenge wounds you. -\(damage) Endurance.", at: 0)
            if s.stats.endurance <= 3 {
                run.finished = true
                run.conquered = false
                run.log.insert("Too wounded to go on, you retreat from \(run.dungeon.name).", at: 0)
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
            bumpFaction(.djinnSpirits, 5, in: &s)
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
        activeRun = nil
        save()
    }

    // MARK: - In-dungeon Djinn abilities

    /// Whether the player owns a given Djinn (public for the dungeon UI).
    func owns(_ djinn: Djinn) -> Bool { has(djinn) }

    /// Room kinds a Djinn's signature ability can overcome outright.
    private func abilityTargets(_ djinn: Djinn) -> Set<RoomKind> {
        switch djinn {
        case .amon:      return [.monster, .boss, .trap]     // Amon's Flame
        case .dantalion: return [.puzzle, .trap, .djinnChamber] // Light of Truth
        case .baal:      return Set(RoomKind.allCases) // Lightning Strike — anything
        case .vinea:     return [.trap, .puzzle]              // Hidden Current
        default:         return []
        }
    }

    /// Djinns whose ability can be invoked on the current room right now.
    func usableAbilities() -> [Djinn] {
        guard let run = activeRun, let room = run.currentRoom, !run.finished else { return [] }
        return [Djinn.amon, .dantalion, .baal, .vinea].filter { djinn in
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

        if s.night > GameState.totalNights {
            state = s
            phase = .ended
            save()
            return
        }

        // Injuries slowly recover on their own by one at night's turn.
        if s.meta.injuries > 0 && Int.random(in: 0...100) < 40 { s.meta.injuries -= 1 }

        // Roll a new blessing/curse for the coming night.
        let newMod = BlessingCatalog.roll(luckAffinity: s.stats.luck)
        s.meta.blessing = newMod
        if let mod = newMod {
            summary.tonightBlessing = mod.name
        }

        // Scale and restore energy for the new era, reduced by lingering injuries.
        s.maxEnergy = s.energyForCurrentEra + (newMod?.energyDelta ?? 0)
        s.energy = max(3, s.maxEnergy - s.meta.injuries)

        // Title advancement note.
        let titleAfter = TitleSystem.currentTitle(for: s)
        if titleAfter != titleBefore { summary.newTitle = titleAfter }

        // Milestone every 100 nights (folded into the summary, no extra sheet).
        if s.night % 100 == 0 {
            if let (line, deltas) = applyMilestone(&s) {
                summary.events.append(line)
                summary.entries.append(NightSummary.Entry(title: "Milestone — Night \(s.night)",
                                                          deltas: deltas, tone: "epic"))
            }
        }

        s.meta.lastSummary = summary
        state = s

        // Present the summary popup first…
        nightSummary = summary

        // …then queue an event to fire once the summary is dismissed.
        // Priority: story choice > rare event > ordinary event.
        bufferedEvent = StoryChoices.pending(for: s)
            ?? RareEvents.maybeTrigger(for: s)
            ?? RandomEvents.maybeTrigger(for: s)

        beginNightTracking()
        AudioManager.shared.setMood(.city)
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
