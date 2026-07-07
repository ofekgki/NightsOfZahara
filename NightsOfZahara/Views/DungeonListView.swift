//
//  DungeonListView.swift
//  Nights Of Zahara
//
//  Lists discovered dungeons and launches an interactive crawl.
//

import SwiftUI

struct DungeonListView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if game.discoveredDungeons.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "map").font(.system(size: 40)).foregroundStyle(Theme.sand.opacity(0.6))
                        Text("No dungeons discovered yet.")
                            .font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                        Text("Use \"Search for Dungeon\" or \"Journey\" in the Actions tab, follow rumors, or buy a treasure map to reveal a dungeon's location.")
                            .font(Theme.body(13)).foregroundStyle(Theme.sand)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 30).padding(.horizontal)
                } else {
                    ForEach(game.discoveredDungeons) { dungeon in
                        DungeonRow(dungeon: dungeon,
                                   completed: game.isCompleted(dungeon),
                                   canEnter: (game.state?.energy ?? 0) >= 4) {
                            game.enterDungeon(dungeon)
                        }
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Dungeons")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: Binding(
            get: { game.activeRun != nil },
            set: { if !$0 { game.activeRun = nil } })) {
            DungeonRunView().environmentObject(game)
        }
    }
}

struct DungeonRow: View {
    let dungeon: Dungeon
    let completed: Bool
    let canEnter: Bool
    let enter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: dungeon.type.icon)
                    .font(.system(size: 26)).foregroundStyle(Theme.brightGold).frame(width: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(dungeon.name).font(Theme.heading(17)).foregroundStyle(Theme.parchment)
                    Text("\(dungeon.type.rawValue) • \(dungeon.difficultyLabel) • \(dungeon.rooms.count) rooms")
                        .font(Theme.body(12)).foregroundStyle(Theme.sand)
                }
                Spacer()
                if completed {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success).font(.system(size: 22))
                }
            }

            if let djinn = dungeon.djinnReward {
                HStack(spacing: 6) {
                    Image(systemName: djinn.icon).foregroundStyle(djinn.color)
                    Text("Reward: \(djinn.name), \(djinn.domain)")
                        .font(Theme.body(12)).foregroundStyle(Theme.gold)
                }
            }

            if completed {
                Text("Conquered. Its Djinn is yours.")
                    .font(Theme.body(12).italic()).foregroundStyle(Theme.success)
            } else {
                Button(action: enter) {
                    Label("Enter (4 energy)", systemImage: "figure.walk.motion")
                        .font(Theme.body(14).weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(canEnter ? Theme.goldSheen : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                        .foregroundStyle(Theme.deepNight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canEnter)
            }
        }
        .zaharaCard()
    }
}
