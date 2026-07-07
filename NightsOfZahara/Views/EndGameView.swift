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
            row("Role", s.role.rawValue)
            row("Final Gold", "\(s.gold)")
            row("Djinns Bonded", "\(s.djinns.count) / 10")
            row("Dungeons Conquered", "\(s.completedDungeons.count)")
            row("Treasures Found", "\(s.treasuresFound)")
            row("Greatest Strength", s.stats.highest.title)
            row("Reputation", "\(s.stats.reputation)")
            row("Honor", "\(s.stats.honor)")
            row("Allies", "\(s.connections.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
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

    private func finalTitle(_ s: GameState) -> String {
        let sc = score(s)
        if s.djinns.count >= 8 && sc > 400 { return "Master of Djinns" }
        switch sc {
        case ..<80:   return "A Quiet Life in Zahara"
        case ..<160:  return "A Face in the Market"
        case ..<260:  return "A Respected Name"
        case ..<380:  return "Hero of Zahara"
        default:      return "Living Legend of the Thousand Nights"
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
        if s.palaceUnlocked {
            parts.append("Even King Sinbad knew their name within the palace walls.")
        }
        parts.append("And so the thousandth night closed, and a legend was written.")
        return parts.joined(separator: " ")
    }
}
