//
//  CraftingView.swift
//  Nights Of Zahara
//
//  Craft charms, rings and potions from gathered materials + magical dust.
//

import SwiftUI

struct CraftingView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    header(s)
                    ForEach(game.craftableRecipes()) { recipe in
                        recipeCard(recipe, s)
                    }
                    if let next = game.nextCraftingUnlockLevel() {
                        Label("Upgrade your Crafting Room to level \(next) to unlock more — and higher-tier — recipes.",
                              systemImage: "hammer.circle.fill")
                            .font(Theme.body(11).italic())
                            .foregroundStyle(Theme.sand.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .zaharaCard(padding: 12)
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Crafting")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ s: GameState) -> some View {
        HStack {
            Label("\(s.gold) Gold", systemImage: "creditcard.fill").foregroundStyle(Theme.gold)
            Spacer()
            Label("\(s.meta.magicalDust) Dust", systemImage: "sparkles").foregroundStyle(.purple)
        }
        .font(Theme.body(14).weight(.semibold))
        .zaharaCard(padding: 12)
    }

    private func recipeCard(_ recipe: CraftRecipe, _ s: GameState) -> some View {
        let output = ItemCatalog.item(id: recipe.outputID)
        let cost = game.craftCost(recipe)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: output?.category.icon ?? "sparkles")
                    .foregroundStyle(output?.rarity.color ?? Theme.gold)
                VStack(alignment: .leading, spacing: 1) {
                    Text(output?.name ?? recipe.outputID)
                        .font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                    Text(output?.detail ?? "").font(Theme.body(11)).foregroundStyle(Theme.sand)
                }
                Spacer()
            }
            // Requirements
            VStack(alignment: .leading, spacing: 3) {
                ForEach(recipe.materials.sorted(by: { $0.key < $1.key }), id: \.key) { mat, need in
                    let have = game.materialCount(mat)
                    reqLine(name: ItemCatalog.item(id: mat)?.name ?? mat, have: have, need: need)
                }
                if cost.dust > 0 {
                    reqLine(name: "Magical Dust", have: s.meta.magicalDust, need: cost.dust)
                }
                if cost.gold > 0 {
                    reqLine(name: "Gold", have: s.gold, need: cost.gold)
                }
            }
            let owned = game.alreadyCrafted(recipe)
            Button {
                game.craft(recipe)
            } label: {
                Text(owned ? "Already Owned" : "Craft").font(Theme.body(13).weight(.bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(game.canCraft(recipe) ? Theme.goldSheen
                                : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(Theme.deepNight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!game.canCraft(recipe))
            if owned {
                Text("You may hold only one of each crafted item at a time.")
                    .font(Theme.body(10).italic()).foregroundStyle(Theme.sand.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func reqLine(name: String, have: Int, need: Int) -> some View {
        HStack {
            Text(name).font(Theme.body(12)).foregroundStyle(Theme.sand)
            Spacer()
            Text("\(have)/\(need)")
                .font(Theme.body(12).weight(.semibold).monospacedDigit())
                .foregroundStyle(have >= need ? Theme.success : Theme.danger)
        }
    }
}
