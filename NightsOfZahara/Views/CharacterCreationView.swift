//
//  CharacterCreationView.swift
//  Nights Of Zahara
//
//  Name the hero and choose one of the five starting roles.
//

import SwiftUI

struct CharacterCreationView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedRole: Role = .marketOrphan

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Intro
                    VStack(spacing: 8) {
                        Text("Your Legend Begins")
                            .font(Theme.title(26))
                            .foregroundStyle(Theme.brightGold)
                        Text("In the magical desert city of Zahara, under the reign of King Sinbad and the watchful eye of Scheherazade, your story starts tonight.")
                            .font(Theme.body(14))
                            .foregroundStyle(Theme.sand)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Your Name")
                        TextField("Enter a name…", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(Theme.body(16))
                            .padding()
                            .background(Color.black.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
                            .foregroundStyle(Theme.parchment)
                    }
                    .padding(.horizontal)

                    // Roles
                    SectionTitle(text: "Choose Your Path")
                        .padding(.horizontal)

                    VStack(spacing: 14) {
                        ForEach(Role.allCases) { role in
                            RoleCardView(role: role, selected: selectedRole == role)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) { selectedRole = role }
                                }
                        }
                    }
                    .padding(.horizontal)

                    PrimaryButton(title: "Enter Zahara", icon: "arrow.right.circle.fill") {
                        game.startNewGame(name: name, role: selectedRole)
                        dismiss()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .padding(.vertical)
            }
            .nightBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundStyle(Theme.sand)
                }
            }
        }
    }
}

struct RoleCardView: View {
    let role: Role
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: role.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.brightGold)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.rawValue)
                        .font(Theme.heading(18))
                        .foregroundStyle(Theme.parchment)
                    Text(role.tagline)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.sand)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                        .font(.system(size: 22))
                }
            }

            Text(role.description)
                .font(Theme.body(13))
                .foregroundStyle(Theme.sand.opacity(0.95))

            // Bonus chips
            let b = role.bonuses
            let bonusChips: [(String, Int)] = StatKind.allCases
                .map { ($0.title, b[$0]) }
                .filter { $0.1 != 0 }
            FlowChips(items: bonusChips.map { chip in
                (chip.1 > 0 ? "+\(chip.1) \(chip.0)" : "\(chip.1) \(chip.0)", chip.1 > 0)
            })

            HStack(spacing: 6) {
                Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Theme.gold)
                Text(role.playstyle)
                    .font(Theme.body(12).italic())
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(16)
        .background(Theme.cardFill)
        .background(Theme.nightBlue.opacity(selected ? 0.55 : 0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(selected ? Theme.brightGold : Theme.gold.opacity(0.3),
                          lineWidth: selected ? 2 : 1))
    }
}

/// A simple wrapping row of small chips.
struct FlowChips: View {
    /// (label, isPositive)
    let items: [(String, Bool)]

    var body: some View {
        // Use a LazyVGrid-like wrap via adaptive grid.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item.0)
                    .font(Theme.body(11).weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((item.1 ? Theme.success : Theme.danger).opacity(0.22))
                    .foregroundStyle(item.1 ? Theme.success : Theme.danger)
                    .clipShape(Capsule())
            }
        }
    }
}
