//
//  UpgradeView.swift
//  Nights Of Zahara
//
//  Spend gold and energy to permanently raise a stat.
//

import SwiftUI

struct UpgradeView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    HStack {
                        Text("Hone Yourself").font(Theme.heading(18)).foregroundStyle(Theme.brightGold)
                        Spacer()
                        Label("\(s.gold)", systemImage: "creditcard.fill")
                            .font(Theme.body(15).weight(.semibold)).foregroundStyle(Theme.gold)
                    }
                    Text("Each improvement costs \(GameViewModel.upgradeEnergyCost) energy and rises in gold as the stat grows. No stat can pass \(Stats.cap).")
                        .font(Theme.body(12)).foregroundStyle(Theme.sand)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Wealth is tied to your fortune, not manual training.
                    HStack(spacing: 12) {
                        Image(systemName: StatKind.wealth.icon).foregroundStyle(StatKind.wealth.color).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wealth").font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                            Text("Current: \(s.stats.wealth) — rises and falls with your gold.")
                                .font(Theme.body(12)).foregroundStyle(Theme.sand)
                        }
                        Spacer()
                        InfoDot(title: "Wealth", message: StatKind.wealth.explanation)
                    }
                    .zaharaCard(padding: 12)

                    ForEach(StatKind.allCases.filter { $0 != .wealth }) { kind in
                        HStack(spacing: 12) {
                            Image(systemName: kind.icon).foregroundStyle(kind.color).frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title).font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                                Text("Current: \(s.stats[kind])").font(Theme.body(12)).foregroundStyle(Theme.sand)
                            }
                            Spacer()
                            if game.isStatMaxed(kind) {
                                Text("Max")
                                    .font(Theme.body(13).weight(.bold))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .foregroundStyle(Theme.success)
                            } else {
                                Button {
                                    game.upgrade(kind)
                                } label: {
                                    Text("+1 · \(game.upgradeCost(for: kind))g")
                                        .font(Theme.body(13).weight(.bold))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(game.canUpgrade(kind) ? Theme.goldSheen : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                                        .foregroundStyle(Theme.deepNight)
                                        .clipShape(Capsule())
                                }
                                .disabled(!game.canUpgrade(kind))
                            }
                        }
                        .zaharaCard(padding: 12)
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }.foregroundStyle(Theme.brightGold)
            }
        }
    }
}
