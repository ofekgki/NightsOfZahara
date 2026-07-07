//
//  CompanionView.swift
//  Nights Of Zahara
//
//  Meet and recruit companions who travel with you and lend their talents.
//

import SwiftUI

struct CompanionView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if game.state != nil {
                    let active = game.companionsActive()
                    let available = game.companionsAvailable()
                    let locked = game.companionsLocked()

                    SectionTitle(text: "Your Companions")
                    if active.isEmpty {
                        Text("You travel alone. Recruit companions to aid your journey.")
                            .font(Theme.body(13)).foregroundStyle(Theme.sand)
                            .frame(maxWidth: .infinity, alignment: .leading).zaharaCard()
                    } else {
                        ForEach(active) { c in card(c, status: .recruited) }
                    }

                    if !available.isEmpty {
                        SectionTitle(text: "Ready to Recruit")
                        ForEach(available) { c in card(c, status: .available) }
                    }
                    if !locked.isEmpty {
                        SectionTitle(text: "Not Yet Available")
                        ForEach(locked) { c in card(c, status: .locked) }
                    }
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Companions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private enum Status { case recruited, available, locked }

    private func card(_ c: Companion, status: Status) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 26)).foregroundStyle(status == .locked ? Theme.sand.opacity(0.5) : Theme.brightGold)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.name).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                    Text(c.role).font(Theme.body(12)).foregroundStyle(Theme.gold)
                }
                Spacer()
            }
            Text(c.personality).font(Theme.body(12).italic()).foregroundStyle(Theme.sand)
            Label("+\(c.bonusAmount) \(c.bonusKind.label)", systemImage: "sparkles")
                .font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.success)

            switch status {
            case .recruited:
                Label(c.questText, systemImage: "scroll").font(Theme.body(11)).foregroundStyle(Theme.sand)
            case .available:
                Button {
                    game.recruit(c)
                } label: {
                    Text("Recruit · \(c.recruitCost)g").font(Theme.body(13).weight(.bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background((game.state?.gold ?? 0) >= c.recruitCost ? Theme.goldSheen
                                    : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
                        .foregroundStyle(Theme.deepNight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled((game.state?.gold ?? 0) < c.recruitCost)
            case .locked:
                Label(c.unlockHint, systemImage: "lock.fill").font(Theme.body(11)).foregroundStyle(Theme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
        .opacity(status == .locked ? 0.7 : 1)
    }
}
