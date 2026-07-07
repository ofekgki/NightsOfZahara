//
//  GameViewModel+Features2.swift
//  Nights Of Zahara
//
//  Side quests, crafting, home upgrades, companions and the shared faction /
//  home / companion bonus helpers used by the action resolvers.
//

import SwiftUI

extension GameViewModel {

    // MARK: - Side quests (the general quest log)

    func sideQuestsOffered() -> [Quest] {
        guard let s = state else { return [] }
        return QuestCatalogGeneral.all.filter { q in
            (q.role == nil || q.role == s.role)
            && !s.meta.acceptedQuests.contains(q.id)
            && !s.meta.finishedQuests.contains(q.id)
            && q.available(s)
        }
    }

    func sideQuestsActive() -> [Quest] {
        guard let s = state else { return [] }
        return s.meta.acceptedQuests.compactMap { QuestCatalogGeneral.quest(id: $0) }
    }

    func sideQuestDone(_ quest: Quest) -> Bool {
        guard let s = state else { return false }
        return quest.objective.isSatisfied(in: s)
    }

    func acceptSideQuest(_ quest: Quest) {
        guard var s = state, !s.meta.acceptedQuests.contains(quest.id) else { return }
        s.meta.acceptedQuests.append(quest.id)
        state = s
        HapticManager.play(.selection)
        present(ActionOutcome(title: "Quest Accepted", message: "\(quest.name) — \(quest.npc)",
                              deltas: [quest.objective.label], tone: .neutral))
    }

    func claimSideQuest(_ quest: Quest) {
        guard var s = state, sideQuestDone(quest),
              s.meta.acceptedQuests.contains(quest.id) else { return }
        s.meta.acceptedQuests.removeAll { $0 == quest.id }
        s.meta.finishedQuests.append(quest.id)
        s.gold += quest.rewardGold
        var deltas: [String] = []
        if quest.rewardGold > 0 { deltas.append("+\(quest.rewardGold) Gold") }
        if let (kind, amt) = quest.rewardStat { s.stats[kind] += amt; deltas.append("+\(amt) \(kind.title)") }
        if let itemID = quest.rewardItemID, let item = ItemCatalog.item(id: itemID) {
            let (_, extra) = grant(item, to: &s)
            deltas.append("Reward: \(item.name)"); deltas += extra
        }
        state = s
        present(ActionOutcome(title: "Quest Complete: \(quest.name)",
                              message: quest.completion, deltas: deltas, tone: .epic))
    }

    // MARK: - Crafting

    func materialCount(_ id: String) -> Int { state?.inventory[id] ?? 0 }

    func craftCost(_ recipe: CraftRecipe) -> (gold: Int, dust: Int) {
        let discount = homeBonus(.craftDiscount)          // percent
        let gold = max(1, Int(Double(recipe.gold) * (1.0 - Double(discount) / 100.0)))
        return (gold, recipe.dust)
    }

    func canCraft(_ recipe: CraftRecipe) -> Bool {
        guard let s = state else { return false }
        let cost = craftCost(recipe)
        guard s.gold >= cost.gold, s.meta.magicalDust >= cost.dust else { return false }
        for (mat, need) in recipe.materials where (s.inventory[mat] ?? 0) < need { return false }
        return true
    }

    func craft(_ recipe: CraftRecipe) {
        guard var s = state, canCraft(recipe), let output = ItemCatalog.item(id: recipe.outputID) else { return }
        let cost = craftCost(recipe)
        s.gold -= cost.gold
        s.meta.magicalDust -= cost.dust
        for (mat, need) in recipe.materials {
            s.inventory[mat, default: 0] -= need
            if (s.inventory[mat] ?? 0) <= 0 { s.inventory[mat] = nil }
        }
        let (msg, extra) = grant(output, to: &s)
        state = s
        HapticManager.play(.success)
        present(ActionOutcome(title: "Crafted \(output.name)", message: msg,
                              deltas: ["-\(cost.gold) Gold", "-\(cost.dust) Dust"] + extra, tone: .epic))
    }

    // MARK: - Home upgrades

    func homeLevel(_ room: HomeRoom) -> Int { state?.meta.homeRooms[room.rawValue] ?? 0 }

    func homeNextCost(_ room: HomeRoom) -> Int { room.cost(toLevel: homeLevel(room) + 1) }

    func canUpgradeHome(_ room: HomeRoom) -> Bool {
        guard let s = state, homeLevel(room) < room.maxLevel else { return false }
        return s.gold >= homeNextCost(room)
    }

    func upgradeHome(_ room: HomeRoom) {
        guard var s = state, canUpgradeHome(room) else { return }
        let cost = homeNextCost(room)
        s.gold -= cost
        let newLevel = homeLevel(room) + 1
        s.meta.homeRooms[room.rawValue] = newLevel
        state = s
        HapticManager.play(.success)
        present(ActionOutcome(title: "\(room.title) — Level \(newLevel)",
                              message: "You improve your home in Zahara. \(room.benefit)",
                              deltas: ["-\(cost) Gold"], tone: .good))
    }

    /// Total home bonus for a gameplay aspect (levels summed; % for some).
    func homeBonus(_ aspect: HomeAspect) -> Int {
        guard let s = state else { return 0 }
        func lvl(_ r: HomeRoom) -> Int { s.meta.homeRooms[r.rawValue] ?? 0 }
        switch aspect {
        case .rest:          return lvl(.resting)
        case .study:         return lvl(.library)
        case .magicStudy:    return lvl(.magic)
        case .train:         return lvl(.training)
        case .dust:          return lvl(.storage)
        case .treasure:      return lvl(.treasure) * 10
        case .craftDiscount: return lvl(.crafting) * 10
        case .dungeonSearch: return lvl(.map)
        }
    }

    // MARK: - Companions

    func companionsAvailable() -> [Companion] {
        guard let s = state else { return [] }
        return CompanionCatalog.all.filter { !s.meta.companions.contains($0.id) && $0.unlock(s) }
    }

    func companionsLocked() -> [Companion] {
        guard let s = state else { return [] }
        return CompanionCatalog.all.filter { !s.meta.companions.contains($0.id) && !$0.unlock(s) }
    }

    func companionsActive() -> [Companion] {
        guard let s = state else { return [] }
        return s.meta.companions.compactMap { CompanionCatalog.companion(id: $0) }
    }

    func recruit(_ companion: Companion) {
        guard var s = state, companion.unlock(s), !s.meta.companions.contains(companion.id),
              s.gold >= companion.recruitCost else { return }
        s.gold -= companion.recruitCost
        s.meta.companions.append(companion.id)
        state = s
        HapticManager.play(.success)
        present(ActionOutcome(title: "\(companion.name) Joins You!",
                              message: "\(companion.personality) — \(companion.questText)",
                              deltas: ["-\(companion.recruitCost) Gold",
                                       "+\(companion.bonusAmount) \(companion.bonusKind.label)"], tone: .epic))
    }

    /// Total companion bonus of a given kind across recruited companions.
    func companionBonus(_ kind: CompanionBonusKind) -> Int {
        companionsActive().filter { $0.bonusKind == kind }.reduce(0) { $0 + $1.bonusAmount }
    }

    // MARK: - Faction bonus

    /// A small gameplay bonus derived from standing with a faction.
    func factionBonus(_ faction: Faction) -> Int {
        (state?.meta.faction(faction.rawValue) ?? 0) / 10
    }
}
