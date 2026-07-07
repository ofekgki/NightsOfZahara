//
//  ContentView.swift
//  Nights Of Zahara
//
//  Root router: switches between onboarding, the main game and the ending
//  based on the engine's phase. Also hosts the global event & outcome sheets.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameViewModel()

    var body: some View {
        ZStack {
            switch game.phase {
            case .onboarding:
                OnboardingView()
            case .playing:
                MainTabView()
            case .ended:
                EndGameView()
            }
        }
        .environmentObject(game)
        .preferredColorScheme(.dark)
        .onAppear { AudioManager.shared.startIfNeeded() }
        // Night summary at the start of each new night (shown first).
        .sheet(item: $game.nightSummary) { summary in
            NightSummaryView(summary: summary)
                .environmentObject(game)
        }
        // Random event between nights.
        .sheet(item: eventBinding) { event in
            EventView(event: event)
                .environmentObject(game)
                .presentationDetents([.medium])
        }
        // Result of an action / event.
        .sheet(item: $game.outcome) { outcome in
            OutcomeView(outcome: outcome)
                .presentationDetents([.height(300)])
        }
    }

    // Bridge the non-Identifiable-optional event into a sheet(item:) binding.
    private var eventBinding: Binding<GameEvent?> {
        Binding(get: { game.pendingEvent }, set: { game.pendingEvent = $0 })
    }
}

#Preview {
    ContentView()
}
