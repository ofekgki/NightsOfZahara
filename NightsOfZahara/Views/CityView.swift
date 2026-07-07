//
//  CityView.swift
//  Nights Of Zahara
//
//  The main hub of Zahara: HUD, quick actions, palace/dungeon entries,
//  the story journal and the "End Night" control.
//

import SwiftUI

struct CityView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showEndNightConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if let s = game.state {
                    ScrollView {
                        VStack(spacing: 18) {
                            header(s)
                            quickStats(s)
                            palaceAndDungeons(s)
                            journal(s)
                            endNightButton(s)
                        }
                        .padding()
                    }
                } else {
                    Text("No game in progress.").foregroundStyle(Theme.sand)
                }
            }
            .nightBackground()
            .navigationTitle("Zahara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Zahara").font(Theme.heading(20)).foregroundStyle(Theme.brightGold)
                }
            }
        }
    }

    // MARK: - Sections

    private func header(_ s: GameState) -> some View {
        VStack(spacing: 12) {
            TopHUD(state: s)
            VStack(spacing: 2) {
                Text(s.characterName)
                    .font(Theme.title(24))
                    .foregroundStyle(Theme.parchment)
                Text("\(s.role.rawValue) • Era of \(s.era)")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.sand)
            }
            ProgressView(value: Double(s.night), total: Double(GameState.totalNights))
                .tint(Theme.gold)
        }
        .zaharaCard()
    }

    private func quickStats(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "At a Glance")
            HStack(spacing: 10) {
                miniStat(.honor, s.stats.honor)
                miniStat(.reputation, s.stats.reputation)
                miniStat(.magic, s.stats.magic)
            }
            HStack(spacing: 14) {
                Label("\(s.djinns.count)/10 Djinns", systemImage: "flame")
                Label("\(s.completedDungeons.count) Dungeons", systemImage: "building.columns")
                Label("\(s.treasuresFound) Treasures", systemImage: "shippingbox")
            }
            .font(Theme.body(12))
            .foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func miniStat(_ kind: StatKind, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: kind.icon).foregroundStyle(kind.color)
            Text("\(value)").font(Theme.heading(18).monospacedDigit()).foregroundStyle(Theme.parchment)
            Text(kind.title).font(Theme.body(10)).foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity)
    }

    private func palaceAndDungeons(_ s: GameState) -> some View {
        VStack(spacing: 12) {
            NavigationLink {
                DungeonListView()
            } label: {
                cityRow(icon: "building.columns.fill",
                        title: "Djinn Dungeons",
                        subtitle: game.discoveredDungeons.isEmpty
                            ? "Search the actions to discover one"
                            : "\(game.discoveredDungeons.count) discovered")
            }
            NavigationLink {
                PalaceView()
            } label: {
                cityRow(icon: "crown.fill",
                        title: "Sinbad's Palace",
                        subtitle: palaceSubtitle(s))
            }
        }
    }

    private func palaceSubtitle(_ s: GameState) -> String {
        if let quest = game.activeQuest {
            return game.isActiveQuestComplete ? "Mission ready to claim!" : "Mission: \(quest.title)"
        }
        return s.palaceUnlocked ? "Audiences & royal missions" : "Needs Honor 15 or an invitation"
    }

    private func cityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.brightGold)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                Text(subtitle).font(Theme.body(12)).foregroundStyle(Theme.sand)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.sand.opacity(0.6))
        }
        .zaharaCard(padding: 14)
    }

    private func journal(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "The Chronicle")
            if s.journal.isEmpty {
                Text("Your tale is yet unwritten.").font(Theme.body(13)).foregroundStyle(Theme.sand)
            } else {
                ForEach(s.journal.prefix(6), id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold.opacity(0.7))
                            .padding(.top, 3)
                        Text(line).font(Theme.body(13)).foregroundStyle(Theme.sand)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func endNightButton(_ s: GameState) -> some View {
        VStack(spacing: 8) {
            PrimaryButton(title: "End Night \(s.night)", icon: "moon.fill") {
                showEndNightConfirm = true
            }
            Text("Energy resets and a new night begins.")
                .font(Theme.body(11))
                .foregroundStyle(Theme.sand.opacity(0.7))
        }
        .padding(.top, 4)
        .confirmationDialog("End Night \(s.night)?",
                            isPresented: $showEndNightConfirm, titleVisibility: .visible) {
            Button("End the Night") { game.endNight() }
            Button("Stay Awhile", role: .cancel) {}
        } message: {
            Text("Any remaining energy will be lost.")
        }
    }
}
