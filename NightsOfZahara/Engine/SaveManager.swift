//
//  SaveManager.swift
//  Nights Of Zahara
//
//  Local persistence for a single save slot using a JSON file in the
//  app's Documents directory, with UserDefaults as a light fallback.
//

import Foundation

enum SaveManager {
    private static let fileName = "zahara_save.json"
    private static let defaultsKey = "zahara_save_v1"

    private static var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    static func save(_ state: GameState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        if let url = fileURL {
            try? data.write(to: url, options: .atomic)
        }
        // Fallback mirror so a save survives even if file IO fails.
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func load() -> GameState? {
        if let url = fileURL,
           let data = try? Data(contentsOf: url),
           let state = try? JSONDecoder().decode(GameState.self, from: data) {
            return state
        }
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let state = try? JSONDecoder().decode(GameState.self, from: data) {
            return state
        }
        return nil
    }

    static func hasSave() -> Bool {
        load() != nil
    }

    static func deleteSave() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
