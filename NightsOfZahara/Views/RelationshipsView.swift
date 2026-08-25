//  Standing with key figures (Scheherazade, Sinbad) and the factions of Zahara.

import SwiftUI

struct RelationshipsView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let s = game.state {
                    keyFigures(s)
                    majorCharacters(s)
                    factions(s)
                }
            }
            .padding()
        }
        .nightBackground()
        .navigationTitle("Bonds")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func keyFigures(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Key Figures")
            figureRow(icon: "sparkles", name: "Scheherazade", role: "Sorceress & Guide",
                      value: s.meta.relationship("scheherazade"))
            figureRow(icon: "crown.fill", name: "King Sinbad", role: "Ruler of Zahara",
                      value: s.meta.relationship("sinbad"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func figureRow(icon: String, name: String, role: String, value: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 24)).foregroundStyle(Theme.brightGold).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                Text(role).font(Theme.body(12)).foregroundStyle(Theme.sand)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Faction.standing(value))
                    .font(Theme.body(13).weight(.semibold))
                    .foregroundStyle(Faction.standingColor(value))
                Text("\(value)").font(Theme.body(11).monospacedDigit()).foregroundStyle(Theme.sand)
            }
        }
    }

    private func majorCharacters(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Companions of Zahara")
            ForEach(MajorCharacter.allCases) { c in
                characterCard(c, value: s.meta.relationship(c.relationshipKey))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func characterCard(_ c: MajorCharacter, value: Int) -> some View {
        let tier = CharacterTier.from(value)
        let met = value > 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: c.icon).font(.system(size: 24))
                    .foregroundStyle(met ? c.color : Theme.sand.opacity(0.4)).frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(met ? c.name : "A Stranger Yet to Meet")
                        .font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                    Text(met ? c.role : "Explore Zahara to cross their path")
                        .font(Theme.body(11)).foregroundStyle(Theme.sand)
                }
                Spacer()
                if met {
                    Text(tier.title)
                        .font(Theme.body(12).weight(.bold)).foregroundStyle(tier.color)
                }
            }
            if met {
                // Progress toward the next bond tier.
                if let next = tier.nextThreshold {
                    ProgressView(value: Double(min(value, next)), total: Double(next))
                        .tint(tier.color)
                }
                let benefits = c.benefits(upTo: tier)
                if benefits.isEmpty {
                    Text("Reach Friendly to unlock benefits.")
                        .font(Theme.body(10).italic()).foregroundStyle(Theme.sand.opacity(0.6))
                } else {
                    ForEach(benefits, id: \.self) { benefit in
                        Label(benefit, systemImage: "checkmark.seal.fill")
                            .font(Theme.body(11)).foregroundStyle(Theme.success)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(met ? 1 : 0.7)
    }

    private func factions(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Factions of Zahara")
            ForEach(Faction.allCases) { faction in
                let value = s.meta.faction(faction.rawValue)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: faction.icon).foregroundStyle(Theme.gold).frame(width: 24)
                        Text(faction.title).font(Theme.body(14)).foregroundStyle(Theme.parchment)
                        Spacer()
                        Text(Faction.standing(value))
                            .font(Theme.body(12).weight(.semibold))
                            .foregroundStyle(Faction.standingColor(value))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule().fill(Faction.standingColor(value))
                                .frame(width: max(4, geo.size.width * min(1, Double(max(0, value)) / 80.0)))
                        }
                    }.frame(height: 6)
                    // Benefits begin at the Friendly tier and above.
                    if let benefit = faction.benefit(for: value) {
                        Label(benefit, systemImage: "gift.fill")
                            .font(Theme.body(11).weight(.semibold))
                            .foregroundStyle(Theme.success)
                    } else {
                        Text("Reach Friendly for benefits")
                            .font(Theme.body(10).italic())
                            .foregroundStyle(Theme.sand.opacity(0.6))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }
}
