//
//  DjinnCollectionView.swift
//  Nights Of Zahara
//
//  All ten Djinns with locked / unlocked status, domain, bonus and ability.
//

import SwiftUI

struct DjinnCollectionView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let s = game.state {
                        Text("\(s.bondedDjinnFigures) of \(GameState.totalDjinnFigures) Djinns bonded")
                            .font(Theme.body(14)).foregroundStyle(Theme.sand)
                            .frame(maxWidth: .infinity)
                        kingBanner(s)
                    }
                    ForEach(Djinn.allCases) { djinn in
                        DjinnCardView(djinn: djinn,
                                      unlocked: game.state?.djinns.contains(djinn) ?? false,
                                      dungeon: DungeonCatalog.all.first { $0.djinnReward == djinn },
                                      discovered: dungeonDiscovered(for: djinn))
                    }
                }
                .padding()
            }
            .nightBackground()
            .navigationTitle("Djinns")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dungeonDiscovered(for djinn: Djinn) -> Bool {
        guard let s = game.state,
              let dungeon = DungeonCatalog.all.first(where: { $0.djinnReward == djinn }) else { return false }
        return s.discoveredDungeons.contains(dungeon.id)
    }

    /// A special banner for Al-Mudhib, King of the Djinns (separate figure).
    @ViewBuilder
    private func kingBanner(_ s: GameState) -> some View {
        let bonded = KingOfDjinns.isBonded(s)
        let revealed = KingOfDjinns.isUnlocked(s) || bonded
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: bonded ? "crown.fill" : (revealed ? "flame.fill" : "lock.fill"))
                    .font(.system(size: 26))
                    .foregroundStyle(bonded ? Theme.brightGold : (revealed ? Theme.ember : Theme.sand.opacity(0.5)))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(revealed ? "Al-Mudhib" : "The King of the Djinns")
                        .font(Theme.heading(17)).foregroundStyle(Theme.parchment)
                    Text(revealed ? "King of the Djinns" : "A legend not yet revealed")
                        .font(Theme.body(12)).foregroundStyle(Theme.gold)
                }
                Spacer()
                Text(bonded ? "Crowned" : (revealed ? "Awaits" : "Sealed"))
                    .font(Theme.body(11).weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((bonded ? Theme.success : Theme.ember).opacity(0.2))
                    .foregroundStyle(bonded ? Theme.success : Theme.ember)
                    .clipShape(Capsule())
            }
            Text(revealed
                 ? "The Throne of the Hidden Flame has appeared. Conquer it to be crowned sovereign of the Djinns."
                 : "Bond many Djinns, earn Scheherazade and Sinbad's trust, and walk deep into the hundred nights — then the King may judge you worthy.")
                .font(Theme.body(12)).foregroundStyle(Theme.sand)
        }
        .padding(16)
        .background(Theme.cardFill)
        .background(Theme.royalPurple.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Theme.brightGold.opacity(bonded ? 0.7 : 0.3), lineWidth: 1))
    }
}

struct DjinnCardView: View {
    let djinn: Djinn
    let unlocked: Bool
    let dungeon: Dungeon?
    let discovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: unlocked ? djinn.icon : "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(unlocked ? djinn.color : Theme.sand.opacity(0.5))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(djinn.name).font(Theme.heading(18)).foregroundStyle(Theme.parchment)
                    Text(djinn.domain).font(Theme.body(12)).foregroundStyle(Theme.gold)
                }
                Spacer()
                Text(unlocked ? "Bonded" : "Locked")
                    .font(Theme.body(11).weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((unlocked ? Theme.success : Theme.danger).opacity(0.2))
                    .foregroundStyle(unlocked ? Theme.success : Theme.danger)
                    .clipShape(Capsule())
            }

            infoLine(icon: "star.circle", label: "Bonus", text: djinn.bonusText)
            infoLine(icon: "sparkles", label: djinn.abilityName, text: djinn.abilityText)

            if let dungeon {
                infoLine(icon: dungeon.type.icon, label: "Dungeon",
                         text: discovered || unlocked
                            ? "\(dungeon.name) — \(dungeon.type.rawValue)"
                            : "Location undiscovered. Search to reveal it.")
            } else {
                infoLine(icon: "questionmark.circle", label: "Dungeon",
                         text: "Lost to legend — findable in a future chapter.")
            }
        }
        .padding(16)
        .background(Theme.cardFill)
        .background(Theme.nightBlue.opacity(unlocked ? 0.5 : 0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(unlocked ? djinn.color.opacity(0.7) : Theme.gold.opacity(0.25), lineWidth: 1))
    }

    private func infoLine(icon: String, label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.gold).frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(Theme.body(11).weight(.semibold)).foregroundStyle(Theme.gold)
                Text(text).font(Theme.body(13)).foregroundStyle(Theme.sand)
            }
        }
    }
}
