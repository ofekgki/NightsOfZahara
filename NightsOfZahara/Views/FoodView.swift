//  Eat food from your pack to restore energy or gain small benefits.

import SwiftUI

struct FoodView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var lastMessage: String?

    /// Consumable food/potion items the player currently holds.
    private func heldConsumables(_ s: GameState) -> [(Item, Int)] {
        s.inventory.compactMap { id, count in
            guard let item = ItemCatalog.item(id: id), item.consumable, count > 0 else { return nil }
            return (item, count)
        }
        .sorted { $0.0.name < $1.0.name }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    HStack {
                        Text("Your Provisions").font(Theme.heading(18)).foregroundStyle(Theme.brightGold)
                        Spacer()
                        Label("\(s.energy)/\(s.maxEnergy)", systemImage: "bolt.fill")
                            .font(Theme.body(15).weight(.semibold)).foregroundStyle(Theme.gold)
                    }

                    if let msg = lastMessage {
                        Label(msg, systemImage: "fork.knife.circle.fill")
                            .font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .zaharaCard(padding: 10)
                    }

                    let held = heldConsumables(s)
                    if held.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bag").font(.system(size: 34)).foregroundStyle(Theme.sand.opacity(0.6))
                            Text("You have no food or provisions.\nVisit the shop to stock up.")
                                .font(Theme.body(13)).foregroundStyle(Theme.sand)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        ForEach(held, id: \.0.id) { item, count in
                            HStack(spacing: 12) {
                                Image(systemName: item.category.icon).foregroundStyle(Theme.brightGold).frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(item.name) ×\(count)").font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                                    Text(item.detail).font(Theme.body(12)).foregroundStyle(Theme.sand)
                                }
                                Spacer()
                                Button("Use") { withAnimation { lastMessage = game.useItem(item) } }
                                    .font(Theme.body(14).weight(.bold))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Theme.goldSheen)
                                    .foregroundStyle(Theme.deepNight)
                                    .clipShape(Capsule())
                            }
                            .zaharaCard(padding: 12)
                        }
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }.foregroundStyle(Theme.brightGold)
            }
        }
    }
}
