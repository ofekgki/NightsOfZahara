//
//  JourneyRetrospectiveView.swift
//  Nights Of Zahara
//
//  Shown at each 100-night checkpoint instead of a nightly summary: a grand
//  retrospective of the whole journey so far, with a choice to continue
//  onward or to end the journey and read the final legend.
//

import SwiftUI

struct JourneyRetrospectiveView: View {
    @EnvironmentObject private var game: GameViewModel

    private var nights: Int { game.journeyCheckpointNight ?? GameState.totalNights }

    var body: some View {
        Group {
            if let s = game.state {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 16)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 52)).foregroundStyle(Theme.goldSheen)

                        Text("\(nights) Nights in Zahara")
                            .font(Theme.title(28)).foregroundStyle(Theme.brightGold)
                            .multilineTextAlignment(.center)
                        Text("A milestone in your legend")
                            .font(Theme.body(13).italic()).foregroundStyle(Theme.sand)

                        Text(reflection(s))
                            .font(Theme.body(15).italic())
                            .foregroundStyle(Theme.parchment)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        summary(s)
                        choices
                        Spacer(minLength: 24)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nightBackground()
        .interactiveDismissDisabled()
    }

    // MARK: - Sections

    private func summary(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "\(s.characterName)'s Journey So Far")
            row("Current Title", TitleSystem.currentTitle(for: s))
            row("Starting Role", s.role.rawValue)
            row("Djinns Bonded", "\(s.djinns.count) / \(Djinn.allCases.count)")
            if KingOfDjinns.isBonded(s) { row("King of the Djinns", "Crowned by Al-Mudhib") }
            row("Dungeons Conquered", "\(s.completedDungeons.count)")
            row("Artifacts Held", "\(s.meta.artifacts.count)")
            row("Treasures Found", "\(s.treasuresFound)")
            row("Gold", "\(s.gold)")
            row("Greatest Strength", "\(s.stats.highest.title) \(s.stats[s.stats.highest])")
            row("Scheherazade", Faction.standing(s.meta.relationship("scheherazade")))
            row("King Sinbad", Faction.standing(s.meta.relationship("sinbad")))
            row("Allies", "\(s.connections.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private var choices: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Continue the Journey", icon: "sunrise.fill") {
                game.continueJourney()
            }
            Button {
                game.finishJourney()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Finish the Journey").font(Theme.heading(16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(Theme.parchment)
                .background(Theme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
            }
            Text("Continue to keep living your legend, or finish now to read how the tale is told.")
                .font(Theme.body(11)).foregroundStyle(Theme.sand.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.body(14)).foregroundStyle(Theme.sand)
            Spacer()
            Text(value).font(Theme.body(15).weight(.semibold)).foregroundStyle(Theme.brightGold)
        }
    }

    private func reflection(_ s: GameState) -> String {
        var line = "\(nights) nights have passed since \(s.characterName) first walked into Zahara. "
        if s.djinns.count >= 8 {
            line += "The Djinns whisper their name, and the city calls them legend."
        } else if s.completedDungeons.count >= 3 {
            line += "Dungeons have fallen before them, and their name spreads on the desert wind."
        } else if s.stats.reputation >= 30 {
            line += "The markets and tea houses know them well now."
        } else {
            line += "Their story is still being written, thread by thread."
        }
        return line
    }
}
