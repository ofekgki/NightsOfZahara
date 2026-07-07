//
//  CharacterView.swift
//  Nights Of Zahara
//
//  Full character sheet: all nine stats, role, Djinns, connections and
//  achievements, plus a way to abandon the run.
//

import SwiftUI

struct CharacterView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showAbandon = false

    var body: some View {
        NavigationStack {
            Group {
                if let s = game.state {
                    ScrollView {
                        VStack(spacing: 18) {
                            profile(s)
                            statsCard(s)
                            djinnCard(s)
                            connectionsCard(s)
                            achievementsCard(s)
                            Button(role: .destructive) { showAbandon = true } label: {
                                Text("Abandon This Legend")
                                    .font(Theme.body(14))
                                    .foregroundStyle(Theme.danger)
                            }
                            .padding(.top, 6)
                        }
                        .padding()
                    }
                }
            }
            .nightBackground()
            .navigationTitle("Character")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Abandon your legend?", isPresented: $showAbandon, titleVisibility: .visible) {
                Button("Abandon & Start Over", role: .destructive) { game.abandonAndRestart() }
                Button("Keep Playing", role: .cancel) {}
            } message: {
                Text("This deletes your save permanently.")
            }
        }
    }

    private func profile(_ s: GameState) -> some View {
        VStack(spacing: 6) {
            Image(systemName: s.role.icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.goldSheen)
            Text(s.characterName).font(Theme.title(26)).foregroundStyle(Theme.parchment)
            Text(TitleSystem.currentTitle(for: s))
                .font(Theme.heading(15)).foregroundStyle(Theme.brightGold)
            Text("\(s.role.rawValue) • Night \(s.night) of \(GameState.totalNights) • \(s.era)")
                .font(Theme.body(12)).foregroundStyle(Theme.sand)
            if s.meta.injuries > 0 {
                Label("Injured (\(s.meta.injuries))", systemImage: "bandage.fill")
                    .font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.danger)
            }
        }
        .frame(maxWidth: .infinity)
        .zaharaCard()
    }

    private func statsCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Stats")
            ForEach(StatKind.allCases) { kind in
                StatRowView(kind: kind, value: s.stats[kind])
            }
        }
        .zaharaCard()
    }

    private func djinnCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Djinns (\(s.djinns.count)/10)")
            if s.djinns.isEmpty {
                Text("You have bonded with no Djinns yet. Conquer their dungeons to earn them.")
                    .font(Theme.body(13)).foregroundStyle(Theme.sand)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(s.djinns) { djinn in
                        VStack(spacing: 4) {
                            Image(systemName: djinn.icon).font(.system(size: 20)).foregroundStyle(djinn.color)
                            Text(djinn.name).font(Theme.body(11)).foregroundStyle(Theme.parchment)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func connectionsCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Connections")
            if s.connections.isEmpty {
                Text("You walk alone for now. Build connections to gain allies.")
                    .font(Theme.body(13)).foregroundStyle(Theme.sand)
            } else {
                ForEach(s.connections, id: \.self) { name in
                    Label(name, systemImage: "person.fill")
                        .font(Theme.body(13)).foregroundStyle(Theme.sand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func achievementsCard(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Deeds")
            achievement("Treasures found", "\(s.treasuresFound)", "shippingbox")
            achievement("Dungeons conquered", "\(s.completedDungeons.count)", "building.columns")
            achievement("Artifacts held", "\(s.meta.artifacts.count)/10", "wand.and.stars")
            achievement("Highest stat", s.stats.highest.title, s.stats.highest.icon)
            achievement("Gold amassed", "\(s.gold)", "creditcard")
            achievement("Magical dust", "\(s.meta.magicalDust)", "sparkles")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func achievement(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon).font(Theme.body(13)).foregroundStyle(Theme.sand)
            Spacer()
            Text(value).font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.brightGold)
        }
    }
}
