//
//  Overlays.swift
//  Nights Of Zahara
//
//  The action-outcome sheet and random-event sheet.
//

import SwiftUI

struct OutcomeView: View {
    let outcome: ActionOutcome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: outcome.tone.icon)
                .font(.system(size: 46))
                .foregroundStyle(outcome.tone.color)
                .padding(.top, 8)

            Text(outcome.title)
                .font(Theme.title(24))
                .foregroundStyle(Theme.parchment)
                .multilineTextAlignment(.center)

            Text(outcome.message)
                .font(Theme.body(15))
                .foregroundStyle(Theme.sand)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !outcome.deltas.isEmpty {
                VStack(spacing: 6) {
                    ForEach(outcome.deltas, id: \.self) { delta in
                        Text(delta)
                            .font(Theme.body(15).weight(.semibold))
                            .foregroundStyle(outcome.tone.color)
                    }
                }
            }

            Spacer(minLength: 0)

            PrimaryButton(title: "Continue") { dismiss() }
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.nightSky.ignoresSafeArea())
    }
}

struct EventView: View {
    let event: GameEvent
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.brightGold)
                .padding(.top, 12)

            Text(event.title)
                .font(Theme.title(24))
                .foregroundStyle(Theme.parchment)
                .multilineTextAlignment(.center)

            Text(event.text)
                .font(Theme.body(15))
                .foregroundStyle(Theme.sand)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                ForEach(event.options) { option in
                    Button {
                        game.resolve(event, choosing: option)
                    } label: {
                        Text(option.label)
                            .font(Theme.body(15).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.cardFill)
                            .foregroundStyle(Theme.parchment)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.nightSky.ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}
