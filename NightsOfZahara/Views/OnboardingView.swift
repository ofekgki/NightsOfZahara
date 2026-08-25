//  Title screen: begin a new legend or continue an existing one.

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showCreation = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.goldSheen)
                .shadow(color: Theme.gold.opacity(0.5), radius: 12)

            VStack(spacing: 6) {
                Text("Nights Of")
                    .font(Theme.heading(22))
                    .foregroundStyle(Theme.sand)
                Text("ZAHARA")
                    .font(.system(size: 46, weight: .black, design: .serif))
                    .foregroundStyle(Theme.goldSheen)
                    .tracking(4)
            }

            Text("\"A thousand nights await, and a legend within each one.\"\n— Scheherazade")
                .font(Theme.body(14).italic())
                .foregroundStyle(Theme.sand.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "Begin a New Legend", icon: "sparkles") {
                    showCreation = true
                }
                if game.hasSave {
                    Button {
                        game.continueGame()
                    } label: {
                        Text("Continue Your Tale")
                            .font(Theme.heading(16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(Theme.parchment)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nightBackground()
        .fullScreenCover(isPresented: $showCreation) {
            CharacterCreationView().environmentObject(game)
        }
    }
}
