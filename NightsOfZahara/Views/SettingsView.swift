//
//  SettingsView.swift
//  Nights Of Zahara
//
//  Music / SFX / haptics controls, save status, credits and progress reset.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var game: GameViewModel
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    audioCard
                    hapticsCard
                    saveCard
                    creditsCard
                    Button(role: .destructive) { showReset = true } label: {
                        Text("Reset Progress").font(Theme.body(15)).foregroundStyle(Theme.danger)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .nightBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.brightGold)
                }
            }
            .confirmationDialog("Reset all progress?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete Save & Restart", role: .destructive) { game.abandonAndRestart(); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your current legend.")
            }
        }
    }

    private var audioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Music")
            Toggle(isOn: $settings.musicOn) {
                Label("Background Music", systemImage: "music.note")
                    .foregroundStyle(Theme.parchment)
            }
            .tint(Theme.gold)
            HStack {
                Image(systemName: "speaker.fill").foregroundStyle(Theme.sand)
                Slider(value: $settings.musicVolume, in: 0...1)
                    .tint(Theme.gold)
                    .disabled(!settings.musicOn)
                Image(systemName: "speaker.wave.3.fill").foregroundStyle(Theme.sand)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private var hapticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Feedback")
            Toggle(isOn: $settings.sfxOn) {
                Label("Sound Effects", systemImage: "waveform")
                    .foregroundStyle(Theme.parchment)
            }.tint(Theme.gold)
            Toggle(isOn: $settings.hapticsOn) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                    .foregroundStyle(Theme.parchment)
            }.tint(Theme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private var saveCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Save")
            HStack {
                Image(systemName: "externaldrive.fill.badge.checkmark").foregroundStyle(Theme.success)
                Text(game.hasSave ? "Progress is saved automatically after every action."
                                  : "No save yet.")
                    .font(Theme.body(13)).foregroundStyle(Theme.sand)
            }
            if let s = game.state {
                Text("Night \(s.night) • \(s.characterName) the \(s.role.rawValue)")
                    .font(Theme.body(12)).foregroundStyle(Theme.sand.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "Credits")
            Text("Nights Of Zahara").font(Theme.heading(15)).foregroundStyle(Theme.brightGold)
            Text("An Arabian-fantasy life sim in the spirit of the thousand nights.\nWorld of Zahara, Scheherazade & King Sinbad.\nBuilt with SwiftUI.")
                .font(Theme.body(12)).foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }
}
