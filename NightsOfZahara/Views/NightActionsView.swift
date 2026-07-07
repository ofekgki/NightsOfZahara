//
//  NightActionsView.swift
//  Nights Of Zahara
//
//  Grid of action cards. Instant actions resolve through the engine;
//  shop / upgrade / eat open dedicated sheets.
//

import SwiftUI

struct NightActionsView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var sheet: NightAction?

    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            Group {
                if let s = game.state {
                    ScrollView {
                        VStack(spacing: 16) {
                            TopHUD(state: s)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)

                            if s.energy == 0 {
                                Text("You are out of energy. Return to the City to end the night.")
                                    .font(Theme.body(13))
                                    .foregroundStyle(Theme.ember)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .zaharaCard(padding: 12)
                            }

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(NightAction.allCases) { action in
                                    ActionCardView(action: action,
                                                   available: s.energy >= action.energyCost) {
                                        if action.opensScreen {
                                            sheet = action
                                        } else {
                                            _ = game.perform(action)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("No game in progress.").foregroundStyle(Theme.sand)
                }
            }
            .nightBackground()
            .navigationTitle("Night Actions")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheet) { action in
                NavigationStack {
                    switch action {
                    case .shop:    ShopView()
                    case .upgrade: UpgradeView()
                    case .eat:     FoodView()
                    default:       EmptyView()
                    }
                }
                .environmentObject(game)
            }
        }
    }
}
