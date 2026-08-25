//  The quest log: active side/role/dungeon/Djinn/treasure quests with live
//  progress, plus quests available to accept.

import SwiftUI

struct QuestLogView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = game.state {
                    let active = game.sideQuestsActive()
                    let offered = game.sideQuestsOffered()

                    SectionTitle(text: "Active Quests")
                    if active.isEmpty {
                        Text("No active quests. Accept one below to guide your path.")
                            .font(Theme.body(13)).foregroundStyle(Theme.sand)
                            .frame(maxWidth: .infinity, alignment: .leading).zaharaCard()
                    } else {
                        ForEach(active) { quest in activeCard(quest, s) }
                    }

                    if !offered.isEmpty {
                        SectionTitle(text: "Available Quests")
                        ForEach(offered) { quest in offerCard(quest) }
                    }

                    if !s.meta.finishedQuests.isEmpty {
                        Text("Completed quests: \(s.meta.finishedQuests.count)")
                            .font(Theme.body(12)).foregroundStyle(Theme.success)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                    }

                    Text("Royal missions from King Sinbad are found at the Palace.")
                        .font(Theme.body(11).italic()).foregroundStyle(Theme.sand.opacity(0.7))
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Quests")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func typeBadge(_ quest: Quest) -> some View {
        Label(quest.type.title, systemImage: quest.type.icon)
            .font(Theme.body(10).weight(.bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(quest.type.color.opacity(0.2))
            .foregroundStyle(quest.type.color)
            .clipShape(Capsule())
    }

    private func activeCard(_ quest: Quest, _ s: GameState) -> some View {
        let p = quest.objective.progress(in: s)
        let done = game.sideQuestDone(quest)
        return VStack(alignment: .leading, spacing: 8) {
            HStack { typeBadge(quest); Spacer()
                Text(done ? "Ready!" : "In progress")
                    .font(Theme.body(11).weight(.semibold))
                    .foregroundStyle(done ? Theme.success : Theme.sand)
            }
            Text(quest.name).font(Theme.heading(16)).foregroundStyle(Theme.brightGold)
            Text(quest.description).font(Theme.body(13)).foregroundStyle(Theme.sand)
            Label(quest.objective.label, systemImage: "target").font(Theme.body(12)).foregroundStyle(Theme.parchment)
            ProgressView(value: Double(min(p.current, p.target)), total: Double(max(1, p.target)))
                .tint(done ? Theme.success : Theme.gold)
            HStack {
                Text("\(min(p.current, p.target)) / \(p.target)").font(Theme.body(11).monospacedDigit()).foregroundStyle(Theme.sand)
                Spacer()
                Label(quest.location, systemImage: "mappin.and.ellipse").font(Theme.body(11)).foregroundStyle(Theme.sand)
            }
            if done {
                PrimaryButton(title: "Claim Reward", icon: "gift.fill") { game.claimSideQuest(quest) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func offerCard(_ quest: Quest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { typeBadge(quest); Spacer()
                HStack(spacing: 4) {
                    Circle().fill(quest.risk.color).frame(width: 7, height: 7)
                    Text(quest.risk.rawValue).font(Theme.body(10)).foregroundStyle(quest.risk.color)
                }
            }
            Text(quest.name).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
            Text(quest.description).font(Theme.body(13)).foregroundStyle(Theme.sand)
            HStack(spacing: 10) {
                Label(quest.npc, systemImage: "person.fill").font(Theme.body(11)).foregroundStyle(Theme.gold)
                Label(quest.location, systemImage: "mappin").font(Theme.body(11)).foregroundStyle(Theme.gold)
            }
            Button {
                game.acceptSideQuest(quest)
            } label: {
                Text("Accept Quest").font(Theme.body(13).weight(.bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(Theme.goldSheen).foregroundStyle(Theme.deepNight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }
}
