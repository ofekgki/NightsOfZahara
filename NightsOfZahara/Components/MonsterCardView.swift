//  Detailed stat card for a dungeon monster / boss.

import SwiftUI

struct MonsterCardView: View {
    let monster: Monster
    var isBoss: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isBoss ? "crown.fill" : "pawprint.fill")
                    .foregroundStyle(isBoss ? Theme.brightGold : Theme.ember)
                Text(monster.name).font(Theme.heading(17)).foregroundStyle(Theme.parchment)
                Spacer()
                Text("Lv \(monster.level)")
                    .font(Theme.body(12).weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.danger.opacity(0.25)).foregroundStyle(Theme.danger)
                    .clipShape(Capsule())
            }

            HStack(spacing: 14) {
                stat("heart.fill", "\(monster.health)", .red)
                stat("bolt.fill", "\(monster.attack)", .orange)
                stat("shield.fill", "\(monster.defense)", .cyan)
                stat("sparkles", "\(monster.magic)", .purple)
                stat("hare.fill", "\(monster.speed)", .green)
            }

            infoLine("bolt.trianglebadge.exclamationmark", "Special", monster.special)
            infoLine("target", "Weakness", monster.weakness)
            infoLine("gift.fill", "Reward", monster.reward)
        }
        .padding(14)
        .background(Theme.cardFill)
        .background(Theme.nightBlue.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder((isBoss ? Theme.brightGold : Theme.ember).opacity(0.5), lineWidth: 1))
    }

    private func stat(_ icon: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(color)
            Text(value).font(Theme.body(12).weight(.semibold).monospacedDigit()).foregroundStyle(Theme.parchment)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoLine(_ icon: String, _ label: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Theme.gold).frame(width: 16)
            Text("\(label): ").font(Theme.body(12).weight(.semibold)).foregroundStyle(Theme.gold)
            + Text(text).font(Theme.body(12)).foregroundStyle(Theme.sand)
        }
    }
}
