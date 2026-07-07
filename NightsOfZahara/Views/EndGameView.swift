//
//  EndGameView.swift
//  Nights Of Zahara
//
//  Shown after Night 1000: a final title, legend and summary of the life
//  the player built across a thousand nights.
//

import SwiftUI

struct EndGameView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        Group {
            if let s = game.state {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 20)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 56)).foregroundStyle(Theme.goldSheen)

                        Text("The 1000th Night")
                            .font(Theme.body(15)).foregroundStyle(Theme.sand)
                        Text(finalTitle(s))
                            .font(Theme.title(30)).foregroundStyle(Theme.brightGold)
                            .multilineTextAlignment(.center)

                        Text(legend(s))
                            .font(Theme.body(15).italic())
                            .foregroundStyle(Theme.parchment)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        summary(s)

                        PrimaryButton(title: "Begin a New Legend", icon: "arrow.clockwise") {
                            game.abandonAndRestart()
                        }
                        .padding(.horizontal)
                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nightBackground()
    }

    private func summary(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "\(s.characterName)'s Legend")
            row("Starting Role", s.role.rawValue)
            row("Final Title", TitleSystem.currentTitle(for: s))
            row("Greatest Achievement", greatestAchievement(s))
            row("Strongest Djinn", strongestDjinn(s))
            row("Key Artifact", keyArtifact(s))
            row("Final Gold", "\(s.gold)")
            row("Djinns Bonded", "\(s.djinns.count) / 10")
            row("Dungeons Conquered", "\(s.completedDungeons.count)")
            row("Treasures Found", "\(s.treasuresFound)")
            row("Greatest Strength", s.stats.highest.title)
            row("Scheherazade", Faction.standing(s.meta.relationship("scheherazade")))
            row("King Sinbad", Faction.standing(s.meta.relationship("sinbad")))
            row("Allies", "\(s.connections.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func greatestAchievement(_ s: GameState) -> String {
        if s.djinns.count >= 8 { return "Bound the Djinns of Zahara" }
        if s.completedDungeons.count >= 5 { return "Conqueror of Dungeons" }
        if s.gold >= 2000 { return "Amassed a great fortune" }
        if s.completedQuestIDs.count >= 3 { return "Champion of King Sinbad" }
        if s.treasuresFound >= 10 { return "Renowned treasure hunter" }
        return "Survived a thousand nights"
    }

    private func strongestDjinn(_ s: GameState) -> String {
        s.djinns.max { $0.statBonus.endurance + $0.statBonus.magic < $1.statBonus.endurance + $1.statBonus.magic }?.name ?? "None"
    }

    private func keyArtifact(_ s: GameState) -> String {
        s.meta.artifacts.compactMap { ArtifactCatalog.artifact(id: $0) }
            .max { $0.rarity < $1.rarity }?.name ?? "None"
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.body(14)).foregroundStyle(Theme.sand)
            Spacer()
            Text(value).font(Theme.body(15).weight(.semibold)).foregroundStyle(Theme.brightGold)
        }
    }

    // MARK: - Ending computation

    private func score(_ s: GameState) -> Int {
        s.djinns.count * 40 + s.completedDungeons.count * 25 + s.treasuresFound * 3
            + s.stats.honor + s.stats.reputation + s.gold / 50
    }

    /// One of several named endings, chosen by the shape of the player's life.
    private func finalTitle(_ s: GameState) -> String {
        let sc = score(s)
        // Distinctive endings first.
        if s.djinns.count >= 8 { return "Master of Djinns" }
        if s.meta.relationship("sinbad") >= 25 && s.completedQuestIDs.count >= 4 { return "King's Champion" }
        if s.gold >= 2500 && s.stats.wealth >= 25 { return "Merchant Prince" }
        if s.completedDungeons.count >= 8 { return "Guardian of Zahara" }
        if s.stats.reputation >= 60 && s.djinns.contains(.zepar) { return "Eternal Storyteller" }
        if s.palaceUnlocked && s.stats.honor >= 50 { return "Palace Hero" }
        if s.treasuresFound >= 15 && s.stats.honor < 20 { return "Cursed Treasure Seeker" }
        // Otherwise fall back to a tier by overall score.
        switch sc {
        case ..<100:  return "Forgotten Wanderer"
        case ..<220:  return "Friend of Zahara"
        case ..<360:  return "Hero of Zahara"
        default:      return "Legend of Zahara"
        }
    }

    private func legend(_ s: GameState) -> String {
        var parts: [String] = []
        parts.append("\(s.characterName), once a \(s.role.rawValue.lowercased()), walked a thousand nights beneath Zahara's stars.")
        if s.djinns.isEmpty {
            parts.append("No Djinn ever bonded to their name, yet their story endured.")
        } else if s.djinns.count >= 8 {
            parts.append("Nearly every Djinn answered their call — Scheherazade herself wove their deeds into the great tales.")
        } else {
            parts.append("\(s.djinns.count) Djinns lent their power to the journey.")
        }
        if s.completedDungeons.count >= 3 {
            parts.append("Dungeons that had slumbered for ages fell before their courage.")
        }
        if s.meta.relationship("sinbad") >= 15 {
            parts.append("King Sinbad counted them among his most trusted, and the court remembered their deeds.")
        } else if s.palaceUnlocked {
            parts.append("Even King Sinbad knew their name within the palace walls.")
        }
        if s.meta.relationship("scheherazade") >= 15 {
            parts.append("Scheherazade wove their tale with special care, for they had been a friend to her across a thousand nights.")
        }
        if !s.meta.artifacts.isEmpty {
            parts.append("The artifacts they gathered still hum with power in the vaults of Zahara.")
        }
        parts.append("And so the thousandth night closed, and a legend was written.")
        return parts.joined(separator: " ")
    }
}
