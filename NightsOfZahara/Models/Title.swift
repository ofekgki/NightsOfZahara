//
//  Title.swift
//  Nights Of Zahara
//
//  Player titles / ranks earned through progression, plus the endgame titles.
//

import Foundation

struct PlayerTitle {
    let name: String
    let requirement: (GameState) -> Bool
}

enum TitleSystem {
    /// Ordered from humblest to grandest. The player's title is the highest
    /// whose requirement is met.
    static let ladder: [PlayerTitle] = [
        PlayerTitle(name: "Market Survivor")   { _ in true },
        PlayerTitle(name: "Treasure Seeker")   { $0.treasuresFound >= 3 },
        PlayerTitle(name: "Friend of Zahara")  { $0.stats.reputation >= 25 },
        PlayerTitle(name: "Palace Guest")      { $0.palaceUnlocked },
        PlayerTitle(name: "Palace Agent")      { $0.completedQuestIDs.count >= 2 },
        PlayerTitle(name: "Dungeon Conqueror") { $0.completedDungeons.count >= 1 },
        PlayerTitle(name: "Djinn Binder")      { $0.djinns.count >= 3 },
        PlayerTitle(name: "Master of Artifacts") { ($0._meta?.artifacts.count ?? 0) >= 4 },
        PlayerTitle(name: "Hero of Zahara")    { $0.completedDungeons.count >= 5 && $0.stats.honor >= 40 },
        PlayerTitle(name: "Legend of Zahara")  { $0.djinns.count >= 8 && $0.completedDungeons.count >= 8 }
    ]

    static func currentTitle(for s: GameState) -> String {
        for title in ladder.reversed() where title.requirement(s) {
            return title.name
        }
        return "Market Survivor"
    }
}
