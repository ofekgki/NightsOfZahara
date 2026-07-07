//
//  GameViewModel+Features.swift
//  Nights Of Zahara
//
//  Expansion systems: unique inventory & dust, equipment, item upgrades,
//  relationships & factions, milestones, titles and the Scheherazade tutorial.
//

import SwiftUI

extension GameViewModel {

    // MARK: - Item granting (unique inventory + duplicate → dust)

    /// Adds an item to the pack. Consumables stack; unique items convert to
    /// magical dust if already owned. Returns a message and extra delta lines.
    @discardableResult
    func grant(_ item: Item, to s: inout GameState) -> (String, [String]) {
        if item.consumable {
            s.inventory[item.id, default: 0] += 1
            return ("\(item.name) added to your pack.", [])
        }
        if s.inventory[item.id] != nil {
            let dust = max(1, item.rarity.valueMultiplier)
            s.meta.magicalDust += dust
            return ("You already own \(item.name); it crumbles into magical dust.",
                    ["+\(dust) Magical Dust"])
        }
        s.inventory[item.id] = 1
        // Non-equippable boosters apply their permanent effect immediately.
        if item.slot == nil {
            applyEffect(item.effect, to: &s)
        }
        return ("\(item.name): \(item.detail)", [])
    }

    /// Public helper for events / journeys to award a found item by id.
    func award(itemID: String) {
        guard var s = state, let item = ItemCatalog.item(id: itemID) else { return }
        let (msg, extra) = grant(item, to: &s)
        state = s
        present(ActionOutcome(title: "Found an Item", message: msg, deltas: extra, tone: .good))
    }

    // MARK: - Shop pricing (blessing/curse + faction discounts)

    func shopPrice(_ item: Item, in s: GameState) -> Int {
        var discount = s.meta.blessing?.shopDiscount ?? 0
        discount += s.meta.faction(Faction.merchants.rawValue) / 10   // merchant favor
        discount += companionBonus(.shopDiscount)
        let factor = max(0.4, 1.0 - Double(discount) / 100.0)
        return max(1, Int(Double(item.price) * factor))
    }

    // MARK: - Equipment

    func equippedItem(_ slot: EquipmentSlot) -> Item? {
        guard let id = state?.meta.equipped[slot.rawValue] else { return nil }
        return ItemCatalog.item(id: id)
    }

    /// Owned, equippable items (in the pack) for a given slot.
    func equippableItems(for slot: EquipmentSlot) -> [Item] {
        guard let s = state else { return [] }
        return s.inventory.keys.compactMap { ItemCatalog.item(id: $0) }
            .filter { $0.slot == slot }
            .sorted { $0.rarity > $1.rarity }
    }

    /// Effective equip bonus for an item at its current upgrade level.
    private func scaledBonus(_ item: Item, level: Int) -> Stats {
        guard let base = item.equipBonus else { return .zero }
        let mult = 1.0 + Double(level) * 0.25
        var out = Stats.zero
        for k in StatKind.allCases { out[k] = Int(Double(base[k]) * mult) }
        return out
    }

    func equip(_ item: Item) {
        guard var s = state, let slot = item.slot else { return }
        // Unequip whatever is there.
        if let currentID = s.meta.equipped[slot.rawValue],
           let current = ItemCatalog.item(id: currentID) {
            s.stats = subtract(s.stats, scaledBonus(current, level: s.meta.itemLevels[currentID] ?? 0))
        }
        s.meta.equipped[slot.rawValue] = item.id
        s.stats = s.stats + scaledBonus(item, level: s.meta.itemLevels[item.id] ?? 0)
        state = s
        HapticManager.play(.selection)
        present(ActionOutcome(title: "Equipped \(item.name)",
                              message: "You ready your \(slot.title.lowercased()).", tone: .good))
    }

    func unequip(_ slot: EquipmentSlot) {
        guard var s = state, let id = s.meta.equipped[slot.rawValue],
              let item = ItemCatalog.item(id: id) else { return }
        s.stats = subtract(s.stats, scaledBonus(item, level: s.meta.itemLevels[id] ?? 0))
        s.meta.equipped[slot.rawValue] = nil
        state = s
        HapticManager.play(.selection)
    }

    private func subtract(_ a: Stats, _ b: Stats) -> Stats {
        var out = a
        for k in StatKind.allCases { out[k] = max(0, a[k] - b[k]) }
        return out
    }

    // MARK: - Item upgrades

    func itemLevel(_ item: Item) -> Int { state?.meta.itemLevels[item.id] ?? 0 }

    /// Cost to upgrade: rises with rarity and current level.
    func upgradeItemCost(_ item: Item) -> (gold: Int, dust: Int) {
        let lvl = itemLevel(item)
        let gold = (60 + lvl * 40) * item.rarity.valueMultiplier / 2
        let dust = 2 + lvl * 2
        return (max(20, gold), dust)
    }

    var maxItemLevel: Int { 4 } // Lv1..Lv3, Masterwork(4)... treat 0-based to 4

    func itemLevelName(_ level: Int) -> String {
        switch level {
        case 0: return "Level 1"
        case 1: return "Level 2"
        case 2: return "Level 3"
        case 3: return "Masterwork"
        default: return "Legendary"
        }
    }

    func canUpgradeItem(_ item: Item) -> Bool {
        guard let s = state, item.isEquippable, itemLevel(item) < maxItemLevel else { return false }
        let cost = upgradeItemCost(item)
        return s.gold >= cost.gold && s.meta.magicalDust >= cost.dust
    }

    func upgradeItem(_ item: Item) {
        guard var s = state, canUpgradeItem(item) else { return }
        let cost = upgradeItemCost(item)
        let currentLevel = itemLevel(item)
        let wasEquipped = isEquipped(item)
        // Remove the currently-applied bonus so we can re-apply the upgraded one.
        if wasEquipped {
            s.stats = subtract(s.stats, scaledBonus(item, level: currentLevel))
        }
        s.gold -= cost.gold
        s.meta.magicalDust -= cost.dust
        let newLevel = currentLevel + 1
        s.meta.itemLevels[item.id] = newLevel
        if wasEquipped {
            s.stats = s.stats + scaledBonus(item, level: newLevel)
        }
        state = s
        present(ActionOutcome(title: "\(item.name) — \(itemLevelName(newLevel))",
                              message: "You reforge the \(item.name), and its power grows.",
                              deltas: ["-\(cost.gold) Gold", "-\(cost.dust) Dust"], tone: .epic))
    }

    // MARK: - Relationships & factions

    func bumpRelationship(_ key: String, _ amount: Int, in s: inout GameState) {
        s.meta.relationships[key, default: 0] += amount
    }
    func bumpFaction(_ faction: Faction, _ amount: Int, in s: inout GameState) {
        s.meta.factions[faction.rawValue, default: 0] += amount
    }

    /// Credit factions based on the action just taken.
    func creditFactions(for action: NightAction) {
        guard var s = state else { return }
        switch action {
        case .work:           bumpFaction(.merchants, 1, in: &s); bumpFaction(.citizens, 1, in: &s)
        case .study:          bumpFaction(.magicians, 1, in: &s); bumpRelationship("scheherazade", 1, in: &s)
        case .train:          bumpFaction(.guards, 1, in: &s)
        case .journey:        bumpFaction(.sailors, 1, in: &s)
        case .searchTreasure: bumpFaction(.thieves, 1, in: &s)
        case .searchDungeon:  bumpFaction(.magicians, 1, in: &s)
        case .connections:    bumpFaction(.citizens, 2, in: &s)
        case .palace:         bumpFaction(.nobles, 1, in: &s); bumpFaction(.guards, 1, in: &s)
                              bumpRelationship("sinbad", 1, in: &s)
        default: break
        }
        state = s
    }

    var relationshipScheherazade: Int { state?.meta.relationship("scheherazade") ?? 0 }
    var relationshipSinbad: Int { state?.meta.relationship("sinbad") ?? 0 }

    // MARK: - Milestones (every 100 nights)

    /// Applies a 100-night milestone's rewards to `s` and returns a summary
    /// line + delta list, or nil if this milestone was already granted.
    func applyMilestone(_ s: inout GameState) -> (String, [String])? {
        let milestone = (s.night / 100) * 100
        guard milestone >= 100, milestone <= 1000,
              !s.meta.completedMilestones.contains(milestone) else { return nil }
        s.meta.completedMilestones.append(milestone)

        let reward = milestone
        s.gold += reward
        s.meta.magicalDust += milestone / 100
        s.pendingDungeonClues += 1

        let messages: [Int: String] = [
            100: "Scheherazade finds you in the market: \"One hundred nights survived. The city knows your name.\"",
            500: "King Sinbad holds a grand ceremony in your honor — half your thousand nights are spent.",
            1000: "The final night dawns. Scheherazade smiles: \"Your legend is nearly written...\""
        ]
        let msg = messages[milestone] ?? "Milestone Night \(milestone): Scheherazade marks the occasion with a gift."
        return (msg, ["+\(reward) Gold", "+\(milestone/100) Dust", "+1 Clue"])
    }

    // MARK: - Title

    var currentTitle: String {
        guard let s = state else { return "Wanderer" }
        return TitleSystem.currentTitle(for: s)
    }

    // MARK: - Injuries / dust convenience

    var injuries: Int { state?.meta.injuries ?? 0 }
    var magicalDust: Int { state?.meta.magicalDust ?? 0 }

    func healAtHealer() {
        guard var s = state, s.gold >= 60, s.meta.injuries > 0 else { return }
        s.gold -= 60
        s.meta.injuries = 0
        state = s
        present(ActionOutcome(title: "The Healer's Care",
                              message: "A healer of Zahara tends your wounds.",
                              deltas: ["-60 Gold", "Injuries mended"], tone: .good))
    }

    // MARK: - Tutorial (Scheherazade, first nights)

    var tutorialTip: String? {
        guard let s = state, s.night <= 7 else { return nil }
        let tips = [
            "\"Each night you have Energy. Spend it wisely on the Actions tab — when it runs low, End the Night to restore it.\"",
            "\"Your nine Stats shape every success. Work for gold, Study for wisdom, Train for courage.\"",
            "\"Search for a Dungeon, then conquer it to bond with a Djinn and claim its artifact.\"",
            "\"Watch the Risk on each action. Greater danger brings greater reward — but injuries too.\"",
            "\"Rest and food heal injuries. Injured heroes tire faster and fight worse.\"",
            "\"Visit the Palace of Sinbad to take royal missions. Honor opens its gates.\"",
            "\"Read the Codex to uncover the lore of Zahara as your legend grows.\""
        ]
        let idx = min(tips.count - 1, max(0, s.night - 1))
        return tips[idx]
    }

    // MARK: - Inventory grouping

    /// Owned items grouped by source category, for the inventory screen.
    func ownedItems() -> [Item] {
        guard let s = state else { return [] }
        return s.inventory.keys.compactMap { ItemCatalog.item(id: $0) }
    }

    func isEquipped(_ item: Item) -> Bool {
        guard let slot = item.slot, let s = state else { return false }
        return s.meta.equipped[slot.rawValue] == item.id
    }
}
