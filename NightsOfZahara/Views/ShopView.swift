//
//  ShopView.swift
//  Nights Of Zahara
//
//  The market shop: buy food, potions, gear, charms and maps with gold.
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var lastMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    HStack {
                        Text("The Grand Bazaar").font(Theme.heading(18)).foregroundStyle(Theme.brightGold)
                        Spacer()
                        Label("\(s.gold)", systemImage: "creditcard.fill")
                            .font(Theme.body(15).weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }

                    if let msg = lastMessage {
                        Label(msg, systemImage: "bag.fill.badge.plus")
                            .font(Theme.body(12).weight(.semibold))
                            .foregroundStyle(Theme.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .zaharaCard(padding: 10)
                    }

                    ForEach(ItemCatalog.shopItems) { item in
                        let price = game.shopPrice(item, in: s)
                        // Buying updates the banner and keeps the shop open.
                        ShopRow(item: item, price: price,
                                canAfford: s.gold >= price,
                                owned: game.alreadyOwnsUnique(item)) {
                            withAnimation { lastMessage = game.buy(item) }
                        }
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AudioManager.shared.setMood(.shop)
            SoundManager.shared.play(.door)     // the shop door swings open
        }
        .onDisappear { AudioManager.shared.setMood(.city) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }.foregroundStyle(Theme.brightGold)
            }
        }
    }
}

struct ShopRow: View {
    let item: Item
    let price: Int
    let canAfford: Bool
    var owned: Bool = false
    let buy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.system(size: 22))
                .foregroundStyle(item.rarity.color)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                    Text(item.rarity.title).font(Theme.body(10).weight(.bold))
                        .foregroundStyle(item.rarity.color)
                }
                Text(item.detail).font(Theme.body(12)).foregroundStyle(Theme.sand)
            }
            Spacer()
            if owned {
                Text("Owned")
                    .font(Theme.body(13).weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .foregroundStyle(Theme.success)
            } else {
                Button(action: buy) {
                    Text("\(price)")
                        .font(Theme.body(14).weight(.bold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(canAfford ? Theme.goldSheen : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                        .foregroundStyle(Theme.deepNight)
                        .clipShape(Capsule())
                }
                .disabled(!canAfford)
            }
        }
        .zaharaCard(padding: 12)
        .opacity(owned ? 0.7 : 1)
    }
}
