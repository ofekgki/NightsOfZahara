//
//  CommonViews.swift
//  Nights Of Zahara
//
//  Small reusable views shared across screens.
//

import SwiftUI

/// A single stat row with icon, label and a filled progress bar.
struct StatRowView: View {
    let kind: StatKind
    let value: Int
    /// Value used to normalize the bar (defaults to 100).
    var scale: Int = 100

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.icon)
                .foregroundStyle(kind.color)
                .frame(width: 26)
            Text(kind.title)
                .font(Theme.body(15))
                .foregroundStyle(Theme.parchment)
                .frame(width: 96, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(kind.color)
                        .frame(width: max(6, geo.size.width * min(1, Double(value) / Double(scale))))
                }
            }
            .frame(height: 8)
            Text("\(value)")
                .font(Theme.body(15).monospacedDigit())
                .foregroundStyle(Theme.brightGold)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

/// Top heads-up display: night, energy and gold.
struct TopHUD: View {
    let state: GameState

    var body: some View {
        HStack(spacing: 10) {
            hudChip(icon: "moon.stars.fill", value: "Night \(state.night)", color: Theme.royalPurple)
            hudChip(icon: "bolt.fill", value: "\(state.energy)/\(state.maxEnergy)", color: Theme.gold)
            hudChip(icon: "creditcard.fill", value: "\(state.gold)", color: Theme.brightGold)
        }
    }

    private func hudChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value)
                .font(Theme.body(14).weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.parchment)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
    }
}

/// A tappable action card for the night-action screen.
struct ActionCardView: View {
    let action: NightAction
    let available: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: action.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(available ? Theme.brightGold : .gray)
                    Spacer()
                    Label("\(action.energyCost)", systemImage: "bolt.fill")
                        .font(Theme.body(12).weight(.semibold))
                        .foregroundStyle(available ? Theme.gold : .gray)
                }
                Text(action.title)
                    .font(Theme.heading(17))
                    .foregroundStyle(Theme.parchment)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(action.rewardHint)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.sand.opacity(0.9))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    Circle().fill(action.risk.color).frame(width: 7, height: 7)
                    Text(action.risk.rawValue)
                        .font(Theme.body(11))
                        .foregroundStyle(action.risk.color)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .zaharaCard(padding: 14)
            .opacity(available ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!available)
    }
}

/// A gold-styled primary button.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon { Image(systemName: icon) }
                Text(title).font(Theme.heading(17))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(enabled ? Theme.goldSheen : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom))
            .foregroundStyle(Theme.deepNight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!enabled)
    }
}

/// Section header in the Arabian serif style.
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.heading(19))
            .foregroundStyle(Theme.brightGold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
