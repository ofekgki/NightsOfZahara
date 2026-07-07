//
//  DungeonRunView.swift
//  Nights Of Zahara
//
//  The interactive dungeon crawl: advance room by room, fight, solve and
//  claim the Djinn at the end.
//

import SwiftUI

struct DungeonRunView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        Group {
            if let run = game.activeRun, let s = game.state {
                VStack(spacing: 16) {
                    header(run, s)
                    roomList(run)
                    if let room = run.currentRoom, !run.finished,
                       room.kind == .monster || room.kind == .boss {
                        MonsterCardView(
                            monster: MonsterFactory.make(for: room, in: run.dungeon, night: s.night),
                            isBoss: room.kind == .boss)
                    }
                    Divider().overlay(Theme.gold.opacity(0.3))
                    logView(run)
                    Spacer(minLength: 0)
                    controls(run, s)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .nightBackground()
            } else {
                Color.clear.nightBackground()
            }
        }
    }

    private func header(_ run: DungeonRun, _ s: GameState) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: run.dungeon.type.icon).foregroundStyle(Theme.brightGold)
                Text(run.dungeon.name).font(Theme.title(22)).foregroundStyle(Theme.parchment)
            }
            ProgressView(value: run.progress).tint(Theme.gold)
            HStack {
                Label("\(s.stats.endurance) Endurance", systemImage: "heart.fill")
                    .foregroundStyle(s.stats.endurance <= 6 ? Theme.danger : Theme.success)
                Spacer()
                Text("Room \(min(run.roomIndex + 1, run.dungeon.rooms.count)) / \(run.dungeon.rooms.count)")
                    .foregroundStyle(Theme.sand)
            }
            .font(Theme.body(13))
        }
        .zaharaCard()
    }

    private func roomList(_ run: DungeonRun) -> some View {
        VStack(spacing: 8) {
            if let room = run.currentRoom, !run.finished {
                VStack(spacing: 6) {
                    Image(systemName: room.kind.icon).font(.system(size: 34)).foregroundStyle(Theme.ember)
                    Text(room.name).font(Theme.heading(18)).foregroundStyle(Theme.parchment)
                    Text("Tests your \(room.kind.testedStat.title)")
                        .font(Theme.body(13)).foregroundStyle(room.kind.testedStat.color)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
            } else if run.finished {
                VStack(spacing: 6) {
                    Image(systemName: run.conquered ? "crown.fill" : "figure.walk.departure")
                        .font(.system(size: 40))
                        .foregroundStyle(run.conquered ? Theme.brightGold : Theme.sand)
                    Text(run.conquered ? "Dungeon Conquered!" : "You Retreated")
                        .font(Theme.title(22))
                        .foregroundStyle(run.conquered ? Theme.brightGold : Theme.sand)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
        }
        .zaharaCard()
    }

    private func logView(_ run: DungeonRun) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(run.log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(Theme.body(13)).foregroundStyle(Theme.sand)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxHeight: 160)
    }

    private func controls(_ run: DungeonRun, _ s: GameState) -> some View {
        VStack(spacing: 10) {
            if !run.finished {
                // Djinn abilities that can clear the current room outright.
                let abilities = game.usableAbilities()
                if !abilities.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(abilities) { djinn in
                            Button {
                                game.useAbility(djinn)
                            } label: {
                                Label("Invoke \(djinn.abilityName)", systemImage: djinn.icon)
                                    .font(Theme.body(13).weight(.semibold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                                    .foregroundStyle(djinn.color)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(djinn.color.opacity(0.6), lineWidth: 1))
                            }
                        }
                    }
                }
                PrimaryButton(title: "Face \(run.currentRoom?.name ?? "the Room")", icon: "arrow.right") {
                    game.resolveCurrentRoom()
                }
                Button("Retreat") { game.retreatDungeon() }
                    .font(Theme.body(14)).foregroundStyle(Theme.danger)
            } else if run.conquered {
                PrimaryButton(title: "Claim Your Reward", icon: "sparkles") {
                    game.claimDungeonReward()
                }
            } else {
                PrimaryButton(title: "Leave the Dungeon", icon: "arrow.uturn.left") {
                    game.retreatDungeon()
                }
            }
        }
    }
}
