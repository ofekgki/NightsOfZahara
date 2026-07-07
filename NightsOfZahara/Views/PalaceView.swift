//
//  PalaceView.swift
//  Nights Of Zahara
//
//  King Sinbad's palace: seek an audience and take on / claim royal missions.
//

import SwiftUI

struct PalaceView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let s = game.state {
                    banner(s)
                    audienceCard(s)
                    missionsCard(s)
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("The Palace")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func banner(_ s: GameState) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40)).foregroundStyle(Theme.goldSheen)
            Text("Palace of King Sinbad")
                .font(Theme.title(22)).foregroundStyle(Theme.parchment)
            Text(s.palaceUnlocked
                 ? "The legendary sailor-king welcomes you."
                 : "Guards eye you warily. Earn Honor 15 or an invitation to be welcomed.")
                .font(Theme.body(13)).foregroundStyle(Theme.sand)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .zaharaCard()
    }

    private func audienceCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Seek an Audience")
            Text("Mingle with nobles and serve the court to earn gold and honor. (2 energy)")
                .font(Theme.body(12)).foregroundStyle(Theme.sand)
            PrimaryButton(title: "Enter the Court", icon: "figure.walk",
                          enabled: s.energy >= 2) {
                game.seekAudience()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func missionsCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Royal Missions")

            if let quest = game.activeQuest {
                activeQuestView(quest, s)
            } else {
                let offers = game.availableQuests()
                if offers.isEmpty {
                    Text("Sinbad has no missions for you now. Return when your legend has grown.")
                        .font(Theme.body(13)).foregroundStyle(Theme.sand)
                } else {
                    Text("King Sinbad offers you a mission:")
                        .font(Theme.body(13)).foregroundStyle(Theme.sand)
                    // Offer the first (humblest) available mission.
                    let quest = offers[0]
                    questOffer(quest)
                }
            }

            if !s.completedQuestIDs.isEmpty {
                Divider().overlay(Theme.gold.opacity(0.2))
                Text("Completed missions: \(s.completedQuestIDs.count)")
                    .font(Theme.body(12)).foregroundStyle(Theme.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func questOffer(_ quest: PalaceQuest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quest.title).font(Theme.heading(16)).foregroundStyle(Theme.brightGold)
            Text(quest.flavor).font(Theme.body(13).italic()).foregroundStyle(Theme.sand)
            Label(quest.objective.label, systemImage: "target")
                .font(Theme.body(13)).foregroundStyle(Theme.parchment)
            rewardLine(quest)
            PrimaryButton(title: "Accept Mission", icon: "hand.raised.fill") {
                game.acceptQuest(quest)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func activeQuestView(_ quest: PalaceQuest, _ s: GameState) -> some View {
        let p = quest.objective.progress(in: s)
        let done = game.isActiveQuestComplete
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quest.title).font(Theme.heading(16)).foregroundStyle(Theme.brightGold)
                Spacer()
                Text(done ? "Ready!" : "Active")
                    .font(Theme.body(11).weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background((done ? Theme.success : Theme.royalPurple).opacity(0.3))
                    .foregroundStyle(done ? Theme.success : Theme.parchment)
                    .clipShape(Capsule())
            }
            Text(quest.flavor).font(Theme.body(13).italic()).foregroundStyle(Theme.sand)
            Label(quest.objective.label, systemImage: "target")
                .font(Theme.body(13)).foregroundStyle(Theme.parchment)
            ProgressView(value: Double(min(p.current, p.target)), total: Double(p.target))
                .tint(done ? Theme.success : Theme.gold)
            Text("\(min(p.current, p.target)) / \(p.target)")
                .font(Theme.body(12).monospacedDigit()).foregroundStyle(Theme.sand)
            rewardLine(quest)
            if done {
                PrimaryButton(title: "Claim Reward", icon: "gift.fill") {
                    game.claimActiveQuest()
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rewardLine(_ quest: PalaceQuest) -> some View {
        var parts: [String] = []
        if quest.rewardGold > 0 { parts.append("\(quest.rewardGold) Gold") }
        if quest.rewardHonor > 0 { parts.append("\(quest.rewardHonor) Honor") }
        if quest.rewardReputation > 0 { parts.append("\(quest.rewardReputation) Reputation") }
        return Label("Reward: \(parts.joined(separator: ", "))", systemImage: "sparkles")
            .font(Theme.body(12)).foregroundStyle(Theme.gold)
    }
}
