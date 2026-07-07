<div align="center">

<img src="Screenshots/app-icon.png" width="120" alt="Nights Of Zahara icon" />

# Nights Of Zahara

**A 1000-night life-simulation / light RPG for iPhone, inspired by *One Thousand and One Nights*.**

Built with **SwiftUI** · **MVVM** · Local save · iOS 26

</div>

---

## ✨ Overview

You arrive in **Zahara**, a magical desert city of markets, storytellers, sailors and palace intrigue. Guided by the sorceress **Scheherazade** and ruled by the legendary sailor-king **Sinbad**, you live out **1000 nights** — one turn each. Every night you spend a limited pool of energy on actions that shape your stats, wealth, reputation and fate.

Your goal: build a personal legend. Work and study, brave journeys, uncover hidden **Djinn dungeons**, conquer them to bond with one of **10 Djinns**, complete King Sinbad's royal missions, and by **Night 1000** earn a final title based on everything you did.

<div align="center">
<img src="Screenshots/onboarding.png" width="260" alt="Title screen" />
&nbsp;&nbsp;
<img src="Screenshots/city.png" width="260" alt="City of Zahara" />
</div>

---

## 🎮 Features

- **The 1000-Night loop** — energy resets each night and scales as your legend grows (6 → 8 → 9 → 10).
- **5 starting roles** — Market Orphan, Wizard Apprentice, Merchant, Sailor, Storyteller — each with distinct stat bonuses, strengths, weaknesses and playstyles.
- **9 character stats** — Wealth, Wisdom, Magic, Reputation, Honor, Luck, Courage, Cunning, Endurance — that drive every success roll.
- **12 nightly actions** — Work, Study, Train, Journey, Search for Dungeon, Enter Palace, Build Connections, Search for Treasure, Rest, Shop, Upgrade, Eat.
- **All 10 Djinns & 10 dungeons** — every Djinn has its own themed, room-by-room dungeon to discover and conquer.
- **Interactive dungeon crawls** — advance through monsters, puzzles, traps, treasure and a boss to the Djinn chamber. Bonded Djinns grant **signature abilities** (Amon's Flame, Light of Truth, Lightning Strike, Hidden Current) that can clear a room outright.
- **King Sinbad's royal missions** — a palace quest board with 7 escalating missions, live progress tracking and rewards.
- **Random events** — mysterious merchants, sandstorms, palace invitations, whispering lamps and more, weighted by your stats and progress.
- **Economy & items** — a 12-item bazaar, consumable provisions, gear that permanently boosts stats, and gold-and-energy stat upgrades.
- **Local save/load** — the whole run persists automatically via `Codable` (JSON file + `UserDefaults` mirror).
- **Endgame** — after Night 1000, a computed final title and a generated legend recapping your deeds.
- **Arabian-fantasy UI** — night-blue / gold / purple theme, parchment cards, five-tab navigation, portrait, one-handed friendly.

---

## 🧭 The Gameplay Loop

```
Start night → energy restored → choose an action → energy spent →
result resolved → rewards/penalties → (maybe a random event) →
repeat while energy remains → End Night → night++ →
… → Night 1000 → Final legend
```

A typical night: *Work* the bazaar for gold, *Study* to raise Wisdom, *Search for Dungeon* to chase a clue, then *End Night* — perhaps a rumor of a desert dungeon surfaces before dawn.

---

## 🧑‍🎨 Starting Roles

| Role | Focus | Key Bonuses |
|------|-------|-------------|
| **Market Orphan** | Risky, treasure-hunting | +Cunning, +Luck, +Courage |
| **Wizard Apprentice** | Magic, Djinns, puzzles | +Magic, +Wisdom (−Endurance) |
| **Merchant** | Economy & connections | +Wealth, +Reputation, +Honor |
| **Sailor** | Journeys & adventure | +Endurance, +Courage, +Luck |
| **Storyteller** | Social & palace | +Reputation, +Wisdom, +Honor |

---

## 🔥 The 10 Djinns & Their Dungeons

| Djinn | Domain | Dungeon | Difficulty |
|-------|--------|---------|:---------:|
| **Phenex** | Healing | Ancient Healing Temple | ★★ |
| **Vinea** | Water | The Sunken Galleon | ★★ |
| **Paimon** | Wind | Cave of Whispers | ★★ |
| **Amon** | Fire | Temple of Fire | ★★★ |
| **Dantalion** | Light | Tower of Dawn | ★★★ |
| **Zepar** | Voice | Hall of Echoes | ★★★ |
| **Ugo** | Home | The Deep Foundations | ★★★ |
| **Barbatos** | Strength | Cavern of Strength | ★★★★ |
| **Baal** | Lightning | Storm Spire | ★★★★ |
| **Zagan** | Life | Garden of Renewal | ★★★★★ |

Each Djinn grants a permanent stat bonus, a passive perk, and a signature ability.

---

## 🏗️ Architecture

The project follows **MVVM** with a single game engine and `Codable` state.

```
NightsOfZahara/
├── NightsOfZaharaApp.swift      # App entry
├── ContentView.swift            # Root router (onboarding / playing / ended)
│
├── Theme/
│   └── Theme.swift              # Colors, gradients, fonts, card styles
│
├── Models/                      # Pure data, all Codable
│   ├── Stats.swift              # 9 stats + StatKind
│   ├── Role.swift               # 5 roles & bonuses
│   ├── Djinn.swift              # 10 Djinns, domains, abilities
│   ├── Dungeon.swift            # Dungeon/room types + 10-dungeon catalog
│   ├── Item.swift               # Shop items & effects
│   ├── NightAction.swift        # Actions, energy costs, risk
│   ├── PalaceQuest.swift        # Royal missions & objectives
│   └── GameState.swift          # The full saved snapshot
│
├── Engine/
│   ├── GameViewModel.swift      # ObservableObject engine: actions, combat,
│   │                            #   dungeons, quests, events, night flow
│   ├── GameEvent.swift          # Random events
│   └── SaveManager.swift        # JSON + UserDefaults persistence
│
├── Components/
│   └── CommonViews.swift        # StatRow, TopHUD, ActionCard, buttons
│
└── Views/                       # One file per screen
    ├── OnboardingView.swift     ├── CharacterView.swift
    ├── CharacterCreationView.swift ├── DjinnCollectionView.swift
    ├── MainTabView.swift        ├── InventoryView.swift
    ├── CityView.swift           ├── DungeonListView.swift
    ├── NightActionsView.swift   ├── DungeonRunView.swift
    ├── ShopView.swift           ├── PalaceView.swift
    ├── UpgradeView.swift        ├── EndGameView.swift
    ├── FoodView.swift           └── Overlays.swift
```

**Data flow:** views observe `GameViewModel` (an `@StateObject` created at the root and shared via `@EnvironmentObject`). All mutations go through the engine, which updates the published `GameState` and saves after every action. The Xcode project uses a *file-system–synchronized* group, so new Swift files under `NightsOfZahara/` are compiled automatically.

---

## 🚀 Getting Started

### Requirements
- macOS with **Xcode 26+**
- iOS 26 Simulator or device

### Run in Xcode
1. Open `NightsOfZahara.xcodeproj`.
2. Select an iPhone simulator (e.g. iPhone 17).
3. Press **⌘R**.

### Build from the command line
```bash
xcodebuild \
  -project NightsOfZahara.xcodeproj \
  -scheme NightsOfZahara \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

> If `xcode-select` points at the Command Line Tools, prefix the command with
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (no `sudo` needed).

---

## 💾 Save Data

A run is stored as `zahara_save.json` in the app's Documents directory, mirrored to `UserDefaults`. It captures the night, character, role, stats, energy, gold, inventory, Djinns, discovered/completed dungeons, connections, active/completed quests and the story journal. Starting a new legend or abandoning one clears the slot.

---

## 🗺️ Roadmap

Foundations exist for several future chapters:

- Active Djinn abilities outside dungeons (e.g. Paimon's extra journey, Zagan's second chance)
- Deeper palace politics & branching royal storylines
- NPC relationship system and rare artifacts
- More endings, achievements, New Game Plus
- Sound, music, animation and iCloud sync

---

## 📜 World & Naming

- **Game:** Nights Of Zahara  ·  **City / hub:** Zahara
- **Sorceress / narrator:** Scheherazade  ·  **King:** Sinbad

---

<div align="center">
<em>"A thousand nights await, and a legend within each one." — Scheherazade</em>
</div>
