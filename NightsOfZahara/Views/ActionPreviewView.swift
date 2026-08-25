//  Shown before an action is confirmed: energy cost, likely rewards, risk,
//  the stats that help, and an estimated chance of a good outcome.

import SwiftUI

struct ActionPreviewView: View {
    let action: NightAction
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: action.icon).font(.system(size: 40)).foregroundStyle(Theme.brightGold)
                .padding(.top, 12)
            Text(action.title).font(Theme.title(24)).foregroundStyle(Theme.parchment)

            HStack(spacing: 10) {
                chip(icon: "bolt.fill", text: "\(effectiveCost) Energy", color: Theme.gold)
                chip(icon: "circle.fill", text: action.risk.rawValue, color: action.risk.color)
                chip(icon: "chart.bar.fill", text: oddsLabel, color: oddsColor)
            }

            infoRow("gift.fill", "Possible rewards", action.rewardHint)
            infoRow("figure.stand", "Stats that help", relatedStats)
            if action.risk == .medium || action.risk == .high {
                infoRow("exclamationmark.triangle.fill", "Possible risks",
                        "Injury, lost gold, or combat if things go poorly.")
            }
            infoRow("sparkle.magnifyingglass", "May trigger", "A random event or discovery.")

            Spacer(minLength: 0)

            PrimaryButton(title: "Do It (\(effectiveCost) Energy)", icon: "checkmark",
                          enabled: (game.state?.energy ?? 0) >= effectiveCost) {
                dismiss()
                DispatchQueue.main.async { _ = game.perform(action) }
            }
            Button("Not Yet") { dismiss() }
                .font(Theme.body(14)).foregroundStyle(Theme.sand)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nightBackground()
    }

    private var effectiveCost: Int { action.energyCost }

    private func chip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
            Text(text).font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.parchment)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(color.opacity(0.18)).clipShape(Capsule())
    }

    private func infoRow(_ icon: String, _ label: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(Theme.gold).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.gold)
                Text(text).font(Theme.body(13)).foregroundStyle(Theme.sand)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard(padding: 12)
    }

    // MARK: - Estimates

    private var helpfulStats: [StatKind] {
        switch action {
        case .work:           return [.wealth, .reputation]
        case .study:          return [.wisdom, .magic]
        case .train:          return [.courage, .endurance]
        case .prowl:          return [.speed, .cunning]
        case .journey:        return [.luck, .endurance, .speed]
        case .searchDungeon:  return [.luck, .wisdom, .magic]
        case .palace:         return [.honor, .reputation]
        case .connections:    return [.reputation, .cunning]
        case .searchTreasure: return [.luck, .cunning]
        default:              return [.luck]
        }
    }

    private var relatedStats: String {
        helpfulStats.map { $0.title }.joined(separator: ", ")
    }

    private var oddsScore: Int {
        guard let s = game.state else { return 0 }
        let sum = helpfulStats.reduce(0) { $0 + s.stats[$1] }
        return sum / max(1, helpfulStats.count) - s.meta.injuries
    }

    private var oddsLabel: String {
        switch oddsScore {
        case ..<10:  return "Poor"
        case ..<20:  return "Fair"
        case ..<32:  return "Good"
        default:     return "Great"
        }
    }

    private var oddsColor: Color {
        switch oddsScore {
        case ..<10:  return Theme.danger
        case ..<20:  return .orange
        case ..<32:  return .green
        default:     return Theme.brightGold
        }
    }
}
