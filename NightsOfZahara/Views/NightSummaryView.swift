//
//  NightSummaryView.swift
//  Nights Of Zahara
//
//  A story-page recap of the night that just ended, shown when a new night
//  begins.
//

import SwiftUI

struct NightSummaryView: View {
    let summary: NightSummary
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if !summary.entries.isEmpty {
                    section("Deeds of the Night") {
                        ForEach(summary.entries) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill").font(.system(size: 5))
                                    .foregroundStyle(Theme.gold).padding(.top, 6)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title).font(Theme.body(14).weight(.semibold))
                                        .foregroundStyle(Theme.parchment)
                                    if !entry.deltas.isEmpty {
                                        Text(entry.deltas.joined(separator: " · "))
                                            .font(Theme.body(12)).foregroundStyle(Theme.sand)
                                    }
                                }
                            }
                        }
                    }
                }

                summaryStats

                if !summary.events.isEmpty {
                    section("Omens & Events") {
                        ForEach(summary.events, id: \.self) { e in
                            Text("• \(e)").font(Theme.body(13)).foregroundStyle(Theme.sand)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                if let title = summary.newTitle {
                    banner(icon: "rosette", text: "You are now known as \(title)!", color: Theme.brightGold)
                }
                if let bless = summary.tonightBlessing {
                    banner(icon: "sparkles", text: "Tonight: \(bless)", color: Theme.royalPurple)
                }

                PrimaryButton(title: "Begin Night \(summary.nextNight)", icon: "sunrise.fill") {
                    dismiss()
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .nightBackground()
        .onDisappear { game.flushBufferedEvent() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "book.pages.fill").font(.system(size: 34)).foregroundStyle(Theme.goldSheen)
            Text("Night \(summary.nightNumber)")
                .font(Theme.title(28)).foregroundStyle(Theme.brightGold)
            Text("A page from your legend").font(Theme.body(13).italic()).foregroundStyle(Theme.sand)
        }
        .padding(.top, 8)
    }

    private var summaryStats: some View {
        section("The Ledger") {
            row("Gold", summary.goldChange >= 0 ? "+\(summary.goldChange)" : "\(summary.goldChange)",
                summary.goldChange >= 0 ? Theme.success : Theme.danger)
            if !summary.statChanges.isEmpty {
                row("Stats", summary.statChanges.joined(separator: ", "), Theme.parchment)
            }
            if summary.injuriesGained > 0 {
                row("Injuries", "+\(summary.injuriesGained)", Theme.danger)
            }
            if summary.goldChange == 0 && summary.statChanges.isEmpty && summary.injuriesGained == 0 {
                Text("A quiet night, all told.").font(Theme.body(13)).foregroundStyle(Theme.sand)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(alignment: .top) {
            Text(label).font(Theme.body(13)).foregroundStyle(Theme.sand)
            Spacer()
            Text(value).font(Theme.body(14).weight(.semibold)).foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
    }

    private func banner(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(Theme.body(14).weight(.semibold)).foregroundStyle(Theme.parchment)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
