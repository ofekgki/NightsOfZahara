//
//  CodexView.swift
//  Nights Of Zahara
//
//  The Lore Book. Browse unlocked entries by category; locked entries hint
//  at what remains to be discovered.
//

import SwiftUI

struct CodexView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var category: CodexCategory = .world

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                picker
                if let s = game.state {
                    let entries = Codex.entries(in: category)
                    ForEach(entries) { entry in
                        entryCard(entry, unlocked: entry.unlock(s))
                    }
                    let unlocked = entries.filter { $0.unlock(s) }.count
                    Text("\(unlocked) / \(entries.count) unlocked in this section")
                        .font(Theme.body(11)).foregroundStyle(Theme.sand.opacity(0.7))
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Codex")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var picker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CodexCategory.allCases) { cat in
                    Button {
                        withAnimation { category = cat }
                    } label: {
                        Text(cat.rawValue)
                            .font(Theme.body(13).weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(category == cat ? Theme.goldSheen
                                        : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                            .foregroundStyle(category == cat ? Theme.deepNight : Theme.sand)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func entryCard(_ entry: CodexEntry, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: unlocked ? "book.closed.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? Theme.brightGold : Theme.sand.opacity(0.5))
                Text(unlocked ? entry.title : "Undiscovered")
                    .font(Theme.heading(16)).foregroundStyle(Theme.parchment)
            }
            Text(unlocked ? entry.body : "This lore is yet to be uncovered. Explore Zahara and grow your legend to reveal it.")
                .font(Theme.body(13)).foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
        .opacity(unlocked ? 1 : 0.6)
    }
}
