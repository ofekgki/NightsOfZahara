//  The main hub of Zahara: HUD, quick actions, palace/dungeon entries,
//  the story journal and the "End Night" control.

import SwiftUI

struct CityView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showEndNightConfirm = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let s = game.state {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 18) {
                                header(s)
                                    .id("cityTop")
                                if let tip = game.tutorialTip { tutorialBanner(tip) }
                                if let bless = s.meta.blessing { blessingBanner(bless) }
                                quickStats(s)
                                places(s)
                                journal(s)
                                endNightButton(s)
                            }
                            .padding()
                        }
                        // When the night advances, snap back to the top of the city.
                        .onChange(of: game.state?.night) { _, _ in
                            withAnimation { proxy.scrollTo("cityTop", anchor: .top) }
                        }
                    }
                } else {
                    Text("No game in progress.").foregroundStyle(Theme.sand)
                }
            }
            .nightBackground()
            .navigationTitle("Zahara")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { AudioManager.shared.setMood(.city) }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Zahara").font(Theme.heading(20)).foregroundStyle(Theme.brightGold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(Theme.gold)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(game)
            }
        }
    }

    private func tutorialBanner(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(Theme.brightGold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Scheherazade").font(Theme.body(12).weight(.bold)).foregroundStyle(Theme.brightGold)
                Text(tip).font(Theme.body(13).italic()).foregroundStyle(Theme.parchment)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.royalPurple.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1))
    }

    private func blessingBanner(_ mod: DailyModifier) -> some View {
        HStack(spacing: 10) {
            Image(systemName: mod.icon)
                .foregroundStyle(mod.kind == .blessing ? Theme.success : Theme.danger)
            VStack(alignment: .leading, spacing: 1) {
                Text(mod.name).font(Theme.body(13).weight(.semibold)).foregroundStyle(Theme.parchment)
                Text(mod.flavor).font(Theme.body(11).italic()).foregroundStyle(Theme.sand)
            }
            Spacer()
            InfoDot(title: mod.name, message: blessingEffectText(mod),
                    icon: mod.kind == .blessing ? "info.circle" : "exclamationmark.triangle.fill",
                    color: mod.kind == .blessing ? Theme.success : Theme.danger)
        }
        .padding(10)
        .background((mod.kind == .blessing ? Theme.success : Theme.danger).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Spell out exactly what a blessing / curse does, for the info popup.
    private func blessingEffectText(_ mod: DailyModifier) -> String {
        var lines: [String] = []
        if mod.luck != 0 { lines.append("\(mod.luck > 0 ? "+" : "")\(mod.luck) to luck on rolls") }
        if mod.treasureBonus != 0 { lines.append("\(mod.treasureBonus > 0 ? "+" : "")\(mod.treasureBonus)% treasure fortune") }
        if mod.dungeonClueBonus != 0 { lines.append("\(mod.dungeonClueBonus > 0 ? "+" : "")\(mod.dungeonClueBonus) dungeon-search fortune") }
        if mod.energyDelta != 0 { lines.append("\(mod.energyDelta > 0 ? "+" : "")\(mod.energyDelta) maximum energy tonight") }
        if mod.combatBonus != 0 { lines.append("\(mod.combatBonus > 0 ? "+" : "")\(mod.combatBonus) combat power") }
        if mod.shopDiscount != 0 { lines.append("\(mod.shopDiscount)% off shop prices") }
        let effects = lines.isEmpty ? "A subtle turn of fortune." : lines.joined(separator: "\n")
        return "\(mod.flavor)\n\n\(effects)"
    }

    // MARK: - Sections

    private func header(_ s: GameState) -> some View {
        VStack(spacing: 12) {
            TopHUD(state: s)
            VStack(spacing: 2) {
                Text(s.characterName)
                    .font(Theme.title(24))
                    .foregroundStyle(Theme.parchment)
                Text("\(s.role.rawValue) • Era of \(s.era)")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.sand)
            }
            ProgressView(value: Double(s.night), total: Double(GameState.totalNights))
                .tint(Theme.gold)
        }
        .zaharaCard()
    }

    private func quickStats(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "At a Glance")
            HStack(spacing: 10) {
                miniStat(.honor, s.stats.honor)
                miniStat(.reputation, s.stats.reputation)
                miniStat(.magic, s.stats.magic)
            }
            HStack(spacing: 14) {
                Label("\(s.bondedDjinnFigures)/\(GameState.totalDjinnFigures) Djinns", systemImage: "flame")
                Label("\(s.completedDungeons.count) Dungeons", systemImage: "building.columns")
                Label("\(s.treasuresFound) Treasures", systemImage: "shippingbox")
            }
            .font(Theme.body(12))
            .foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func miniStat(_ kind: StatKind, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: kind.icon).foregroundStyle(kind.color)
            Text("\(value)").font(Theme.heading(18).monospacedDigit()).foregroundStyle(Theme.parchment)
            Text(kind.title).font(Theme.body(10)).foregroundStyle(Theme.sand)
        }
        .frame(maxWidth: .infinity)
    }

    private func places(_ s: GameState) -> some View {
        VStack(spacing: 12) {
            NavigationLink {
                DungeonListView()
            } label: {
                cityRow(icon: "building.columns.fill",
                        title: "Djinn Dungeons",
                        subtitle: game.discoveredDungeons.isEmpty
                            ? "Search the actions to discover one"
                            : "\(game.discoveredDungeons.count) discovered")
            }
            NavigationLink {
                PalaceView()
            } label: {
                cityRow(icon: "crown.fill",
                        title: "Sinbad's Palace",
                        subtitle: palaceSubtitle(s))
            }
            NavigationLink {
                QuestLogView()
            } label: {
                cityRow(icon: "list.bullet.clipboard.fill", title: "Quests",
                        subtitle: questsSubtitle())
            }
            NavigationLink {
                GearView()
            } label: {
                cityRow(icon: "backpack.fill", title: "Equipment",
                        subtitle: "Equip gear & reforge with dust")
            }
            NavigationLink {
                CraftingView()
            } label: {
                cityRow(icon: "hammer.fill", title: "Crafting",
                        subtitle: "Forge items from materials & dust")
            }
            NavigationLink {
                HomeUpgradeView()
            } label: {
                cityRow(icon: "house.fill", title: "Home",
                        subtitle: "Build rooms for lasting bonuses")
            }
            NavigationLink {
                CompanionView()
            } label: {
                cityRow(icon: "person.3.fill", title: "Companions",
                        subtitle: companionsSubtitle())
            }
            NavigationLink {
                RelationshipsView()
            } label: {
                cityRow(icon: "person.2.fill", title: "Bonds",
                        subtitle: "Scheherazade, Sinbad & factions")
            }
            NavigationLink {
                CodexView()
            } label: {
                cityRow(icon: "books.vertical.fill", title: "Codex",
                        subtitle: "The lore of Zahara")
            }
        }
    }

    private func questsSubtitle() -> String {
        let active = game.sideQuestsActive().count
        return active > 0 ? "\(active) active" : "Find quests to guide your path"
    }

    private func companionsSubtitle() -> String {
        let n = game.companionsActive().count
        return n > 0 ? "\(n) at your side" : "Recruit allies to aid you"
    }

    private func palaceSubtitle(_ s: GameState) -> String {
        if let quest = game.activeQuest {
            return game.isActiveQuestComplete ? "Mission ready to claim!" : "Mission: \(quest.title)"
        }
        return s.palaceUnlocked ? "Audiences & royal missions" : "Needs Honor 15 or an invitation"
    }

    private func cityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.brightGold)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.heading(16)).foregroundStyle(Theme.parchment)
                Text(subtitle).font(Theme.body(12)).foregroundStyle(Theme.sand)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.sand.opacity(0.6))
        }
        .zaharaCard(padding: 14)
    }

    private func journal(_ s: GameState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "The Chronicle")
            if s.journal.isEmpty {
                Text("Your tale is yet unwritten.").font(Theme.body(13)).foregroundStyle(Theme.sand)
            } else {
                // Index-based IDs: journal lines can repeat (e.g. studying
                // twice), so \.self would produce colliding IDs.
                ForEach(Array(s.journal.prefix(6).enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold.opacity(0.7))
                            .padding(.top, 3)
                        Text(line).font(Theme.body(13)).foregroundStyle(Theme.sand)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zaharaCard()
    }

    private func endNightButton(_ s: GameState) -> some View {
        VStack(spacing: 8) {
            PrimaryButton(title: "End Night \(s.night)", icon: "moon.fill") {
                showEndNightConfirm = true
            }
            Text("Energy resets and a new night begins.")
                .font(Theme.body(11))
                .foregroundStyle(Theme.sand.opacity(0.7))
        }
        .padding(.top, 4)
        .confirmationDialog("End Night \(s.night)?",
                            isPresented: $showEndNightConfirm, titleVisibility: .visible) {
            Button("End the Night") { game.endNight() }
            Button("Stay Awhile", role: .cancel) {}
        } message: {
            Text("Any remaining energy will be lost.")
        }
    }
}
