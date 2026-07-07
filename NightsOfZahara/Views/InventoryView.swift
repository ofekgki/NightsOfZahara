//
//  InventoryView.swift
//  Nights Of Zahara
//
//  The player's pack: consumable items held, plus a summary of gear-granted
//  bonuses (which are applied permanently to stats on purchase).
//

import SwiftUI

struct InventoryView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let s = game.state {
                        let held = s.inventory.compactMap { id, count -> (Item, Int)? in
                            guard let item = ItemCatalog.item(id: id), count > 0 else { return nil }
                            return (item, count)
                        }.sorted { $0.0.name < $1.0.name }

                        SectionTitle(text: "Your Pack")
                        if held.isEmpty {
                            emptyState
                        } else {
                            ForEach(held, id: \.0.id) { item, count in
                                HStack(spacing: 12) {
                                    Image(systemName: item.category.icon).foregroundStyle(Theme.brightGold).frame(width: 30)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(item.name) ×\(count)").font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                                        Text(item.detail).font(Theme.body(12)).foregroundStyle(Theme.sand)
                                    }
                                    Spacer()
                                    if canUse(item) {
                                        Button("Use") { game.useItem(item) }
                                            .font(Theme.body(13).weight(.bold))
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(Theme.goldSheen).foregroundStyle(Theme.deepNight)
                                            .clipShape(Capsule())
                                    }
                                }
                                .zaharaCard(padding: 12)
                            }
                        }

                        SectionTitle(text: "Purse")
                        HStack {
                            Label("\(s.gold) Gold", systemImage: "creditcard.fill")
                                .font(Theme.body(15)).foregroundStyle(Theme.gold)
                            Spacer()
                            Label("\(s.pendingDungeonClues) Clues", systemImage: "map.fill")
                                .font(Theme.body(15)).foregroundStyle(Theme.sand)
                        }
                        .zaharaCard(padding: 14)
                    }
                }
                .padding()
            }
            .nightBackground()
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func canUse(_ item: Item) -> Bool {
        // All consumables in the pack are usable from here.
        item.consumable
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag").font(.system(size: 34)).foregroundStyle(Theme.sand.opacity(0.6))
            Text("Your pack is empty.\nBuy provisions and gear at the shop.")
                .font(Theme.body(13)).foregroundStyle(Theme.sand).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
        .zaharaCard()
    }
}
