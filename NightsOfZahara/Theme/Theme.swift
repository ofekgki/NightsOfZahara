//  Arabian-fantasy visual theme: warm desert colors, gold, sand,
//  purple and night-blue. Central place for colors, gradients and fonts.

import SwiftUI

enum Theme {

    // MARK: - Core palette
    static let nightBlue    = Color(red: 0.07, green: 0.09, blue: 0.20)
    static let deepNight    = Color(red: 0.04, green: 0.05, blue: 0.13)
    static let royalPurple  = Color(red: 0.35, green: 0.18, blue: 0.52)
    static let gold         = Color(red: 0.92, green: 0.74, blue: 0.32)
    static let brightGold   = Color(red: 1.00, green: 0.86, blue: 0.45)
    static let sand         = Color(red: 0.86, green: 0.74, blue: 0.55)
    static let parchment    = Color(red: 0.96, green: 0.90, blue: 0.78)
    static let ember        = Color(red: 0.85, green: 0.36, blue: 0.20)
    static let danger       = Color(red: 0.78, green: 0.22, blue: 0.22)
    static let success      = Color(red: 0.36, green: 0.66, blue: 0.42)

    // MARK: - Gradients
    static var nightSky: LinearGradient {
        LinearGradient(
            colors: [deepNight, nightBlue, royalPurple.opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldSheen: LinearGradient {
        LinearGradient(
            colors: [brightGold, gold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Fonts
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}

// MARK: - Reusable view modifiers

/// A parchment / glass style card used across the game.
struct ZaharaCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.cardFill)
            .background(Theme.nightBlue.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1)
            )
    }
}

extension View {
    func zaharaCard(padding: CGFloat = 16) -> some View {
        modifier(ZaharaCard(padding: padding))
    }

    /// Full-screen night-sky background.
    func nightBackground() -> some View {
        self.background(Theme.nightSky.ignoresSafeArea())
    }
}
