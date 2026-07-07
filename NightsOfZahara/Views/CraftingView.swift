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
                    ForEach(CraftCatalog.recipes) { recipe in
                        recipeCard(recipe, s)
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
                reqLine(name: "Magical Dust", have: s.meta.magicalDust, need: cost.dust)
                reqLine(name: "Gold", have: s.gold, need: cost.gold)
            }
            Button {
                game.craft(recipe)
            } label: {
                Text("Craft").font(Theme.body(13).weight(.bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(game.canCraft(recipe) ? Theme.goldSheen
                                : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(Theme.deepNight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!game.canCraft(recipe))
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
