//
//  InventoryView.swift
//  Nights Of Zahara
//
//  The player's pack, grouped by item source, with rarity, equip status,
//  materials and magical dust. Each unique item exists only once.
//

import SwiftUI

struct InventoryView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let s = game.state {
                        purse(s)

                        let held = s.inventory.compactMap { id, count -> (Item, Int)? in
                            guard let item = ItemCatalog.item(id: id), count > 0 else { return nil }
                            return (item, count)
                        }

                        if held.isEmpty {
                            emptyState
                        } else {
                            ForEach(ItemSource.allCases, id: \.self) { source in
                                let group = held.filter { $0.0.source == source }
                                    .sorted { $0.0.rarity > $1.0.rarity }
                                if !group.isEmpty {
                                    sourceSection(source, group)
                                }
                            }
                        }

                        if !s.meta.materials.isEmpty {
                            materialsSection(s)
                        }

                        NavigationLink {
                            GearView()
                        } label: {
                            HStack {
                                Label("Manage Equipment", systemImage: "backpack.fill")
                                    .font(Theme.body(15)).foregroundStyle(Theme.parchment)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Theme.sand.opacity(0.6))
                            }
                            .zaharaCard(padding: 14)
                        }
                    }
                }
                .padding()
            }
            .nightBackground()
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func purse(_ s: GameState) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(s.gold) Gold", systemImage: "creditcard.fill")
                    .font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.gold)
                Spacer()
                Label("\(s.meta.magicalDust) Dust", systemImage: "sparkles")
                    .font(Theme.body(14).weight(.semibold)).foregroundStyle(.purple)
                Spacer()
                Label("\(s.pendingDungeonClues) Clues", systemImage: "map.fill")
                    .font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.sand)
            }
        }
        .zaharaCard(padding: 14)
    }

    private func sourceSection(_ source: ItemSource, _ group: [(Item, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(sourceTitle(source), systemImage: source.icon)
                .font(Theme.heading(16)).foregroundStyle(Theme.brightGold)
            ForEach(group, id: \.0.id) { item, count in
                itemRow(item, count: count)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func sourceTitle(_ s: ItemSource) -> String {
        switch s {
        case .shop: return "Shop Goods"
        case .search: return "Found Treasures"
        case .dungeon: return "Dungeon Spoils"
        case .djinnArtifact: return "Djinn Artifacts"
        case .crafting: return "Materials"
        case .quest: return "Quest Items"
        }
    }

    private func itemRow(_ item: Item, count: Int) -> some View {
        HStack(spacing: 10) {
            Circle().fill(item.rarity.color).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(item.consumable && count > 1 ? "\(item.name) ×\(count)" : item.name)
                        .font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.parchment)
                    if game.isEquipped(item) {
                        Text("Equipped").font(Theme.body(9).weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.success.opacity(0.25)).foregroundStyle(Theme.success)
                            .clipShape(Capsule())
                    }
                }
                Text(item.detail).font(Theme.body(11)).foregroundStyle(Theme.sand)
            }
            Spacer()
            if item.consumable {
                Button("Use") { game.useItem(item) }
                    .font(Theme.body(12).weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Theme.goldSheen).foregroundStyle(Theme.deepNight)
                    .clipShape(Capsule())
            } else if item.isEquippable && !game.isEquipped(item) {
                Button("Equip") { game.equip(item) }
                    .font(Theme.body(12).weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Theme.goldSheen).foregroundStyle(Theme.deepNight)
                    .clipShape(Capsule())
            }
        }
    }

    private func materialsSection(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Crafting Materials", systemImage: "cube.fill")
                .font(Theme.heading(16)).foregroundStyle(Theme.brightGold)
            ForEach(s.meta.materials.sorted(by: { $0.key < $1.key }), id: \.key) { id, count in
                HStack {
                    Text(ItemCatalog.item(id: id)?.name ?? id)
                        .font(Theme.body(13)).foregroundStyle(Theme.parchment)
                    Spacer()
                    Text("×\(count)").font(Theme.body(13).weight(.semibold)).foregroundStyle(Theme.sand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag").font(.system(size: 34)).foregroundStyle(Theme.sand.opacity(0.6))
            Text("Your pack is empty.\nBuy provisions and gear at the shop, or find treasures on your travels.")
                .font(Theme.body(13)).foregroundStyle(Theme.sand).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
        .zaharaCard()
    }
}
