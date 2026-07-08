//
//  GearView.swift
//  Nights Of Zahara
//
//  Equipment slots and item upgrades. Equip owned gear into six slots and
//  reforge equippable items with gold + magical dust.
//

import SwiftUI

struct GearView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    dustHeader(s)
                    ForEach(EquipmentSlot.allCases) { slot in
                        slotCard(slot)
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dustHeader(_ s: GameState) -> some View {
        HStack {
            Label("\(s.gold) Gold", systemImage: "creditcard.fill").foregroundStyle(Theme.gold)
            Spacer()
            Label("\(s.meta.magicalDust) Magical Dust", systemImage: "sparkles").foregroundStyle(.purple)
        }
        .font(Theme.body(14).weight(.semibold))
        .zaharaCard(padding: 12)
    }

    private func slotCard(_ slot: EquipmentSlot) -> some View {
        let equipped = game.equippedItem(slot)
        let options = game.equippableItems(for: slot)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: slot.icon).foregroundStyle(Theme.brightGold).frame(width: 26)
                Text(slot.title).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                Spacer()
                if equipped != nil {
                    Button("Unequip") { game.unequip(slot) }
                        .font(Theme.body(12)).foregroundStyle(Theme.danger)
                }
            }

            if let item = equipped {
                equippedRow(item)
            } else {
                Text("Empty").font(Theme.body(13).italic()).foregroundStyle(Theme.sand.opacity(0.7))
            }

            if !options.isEmpty {
                Text("Owned \(slot.title.lowercased())s").font(Theme.body(11)).foregroundStyle(Theme.sand.opacity(0.7))
                ForEach(options) { item in
                    optionRow(item, isEquipped: game.isEquipped(item))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func equippedRow(_ item: Item) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.category.icon).foregroundStyle(item.rarity.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.name) · \(game.itemLevelName(game.itemLevel(item)))")
                    .font(Theme.body(14).weight(.semibold)).foregroundStyle(item.rarity.color)
                Text(item.detail).font(Theme.body(11)).foregroundStyle(Theme.sand)
                let summary = game.effectiveEquipSummary(item)
                if !summary.isEmpty {
                    Text(summary).font(Theme.body(11).weight(.semibold)).foregroundStyle(Theme.success)
                }
            }
            Spacer()
            InfoDot(title: item.name, message: item.infoText, color: item.rarity.color)
        }
        .padding(10)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func optionRow(_ item: Item, isEquipped: Bool) -> some View {
        let cost = game.upgradeItemCost(item)
        return HStack(spacing: 8) {
            Circle().fill(item.rarity.color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).font(Theme.body(13)).foregroundStyle(Theme.parchment)
                Text("\(item.rarity.title) · \(game.itemLevelName(game.itemLevel(item)))")
                    .font(Theme.body(10)).foregroundStyle(Theme.sand)
                let summary = game.effectiveEquipSummary(item)
                if !summary.isEmpty {
                    Text(summary).font(Theme.body(10).weight(.semibold)).foregroundStyle(Theme.success)
                }
            }
            InfoDot(title: item.name, message: item.infoText, color: item.rarity.color)
            Spacer()
            if game.canUpgradeItem(item) {
                Button {
                    game.upgradeItem(item)
                } label: {
                    Text("Reforge \(cost.dust)✦")
                        .font(Theme.body(11).weight(.bold))
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color.purple.opacity(0.3)).foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
            if !isEquipped {
                Button("Equip") { game.equip(item) }
                    .font(Theme.body(11).weight(.bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.goldSheen).foregroundStyle(Theme.deepNight)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 3)
    }
}
