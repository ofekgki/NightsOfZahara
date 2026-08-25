//  Grid of action cards. Instant actions resolve through the engine;
//  shop / upgrade / eat open dedicated sheets.

import SwiftUI

struct NightActionsView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var sheet: NightAction?
    @State private var preview: NightAction?

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
                                                   available: isAvailable(action, s),
                                                   note: disabledNote(action, s)) {
                                        if action.opensScreen {
                                            sheet = action
                                        } else {
                                            preview = action
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
            .sheet(item: $preview) { action in
                ActionPreviewView(action: action)
                    .environmentObject(game)
                    .presentationDetents([.large])
            }
        }
    }

    /// Whether an action can currently be taken (energy + per-action rules).
    private func isAvailable(_ action: NightAction, _ s: GameState) -> Bool {
        switch action {
        case .rest:          return game.canRest
        case .searchDungeon: return s.energy >= action.energyCost && !game.allDungeonsDiscovered
        default:             return s.energy >= action.energyCost
        }
    }

    /// A short reason an action is disabled, shown on its card.
    private func disabledNote(_ action: NightAction, _ s: GameState) -> String? {
        switch action {
        case .rest where game.restedThisNight:                 return "Already rested tonight"
        case .searchDungeon where game.allDungeonsDiscovered:  return "All dungeons discovered"
        default:                                               return nil
        }
    }
}
