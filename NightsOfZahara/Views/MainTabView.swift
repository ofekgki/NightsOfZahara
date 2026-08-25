//  The five bottom tabs: City, Actions, Character, Djinns, Inventory.

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        TabView {
            CityView()
                .tabItem { Label("City", systemImage: "building.2") }

            NightActionsView()
                .tabItem { Label("Actions", systemImage: "sparkles") }

            CharacterView()
                .tabItem { Label("Character", systemImage: "person.crop.circle") }

            DjinnCollectionView()
                .tabItem { Label("Djinns", systemImage: "flame") }

            InventoryView()
                .tabItem { Label("Inventory", systemImage: "bag") }
        }
        .tint(Theme.brightGold)
    }
}
