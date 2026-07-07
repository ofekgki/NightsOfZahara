//
//  HomeUpgradeView.swift
//  Nights Of Zahara
//
//  Build and upgrade the rooms of your home in Zahara for lasting bonuses.
//

import SwiftUI

struct HomeUpgradeView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    HStack {
                        Text("Your Home in Zahara").font(Theme.heading(17)).foregroundStyle(Theme.brightGold)
                        Spacer()
                        Label("\(s.gold)", systemImage: "creditcard.fill")
                            .font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.gold)
                    }
                    .zaharaCard(padding: 12)

                    ForEach(HomeRoom.allCases) { room in
                        roomCard(room)
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func roomCard(_ room: HomeRoom) -> some View {
        let level = game.homeLevel(room)
        let maxed = level >= room.maxLevel
        let cost = game.homeNextCost(room)
        return HStack(spacing: 12) {
            Image(systemName: room.icon).font(.system(size: 24)).foregroundStyle(Theme.brightGold).frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(room.title).font(Theme.heading(15)).foregroundStyle(Theme.parchment)
                    Text(levelBadge(level, room.maxLevel))
                        .font(Theme.body(10).weight(.bold))
                        .foregroundStyle(level > 0 ? Theme.gold : Theme.sand.opacity(0.6))
                }
                Text(room.benefit).font(Theme.body(11)).foregroundStyle(Theme.sand)
            }
            Spacer()
            if maxed {
                Text("Max").font(Theme.body(12).weight(.bold)).foregroundStyle(Theme.success)
            } else {
                Button {
                    game.upgradeHome(room)
                } label: {
                    VStack(spacing: 1) {
                        Text(level == 0 ? "Build" : "Upgrade").font(Theme.body(11).weight(.bold))
                        Text("\(cost)g").font(Theme.body(10))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(game.canUpgradeHome(room) ? Theme.goldSheen
                                : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(Theme.deepNight)
                    .clipShape(Capsule())
                }
                .disabled(!game.canUpgradeHome(room))
            }
        }
        .zaharaCard(padding: 12)
    }

    private func levelBadge(_ level: Int, _ max: Int) -> String {
        level == 0 ? "Not built" : "Lv \(level)/\(max)"
    }
}
