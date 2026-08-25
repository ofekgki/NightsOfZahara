//  Device-level settings (music, sfx, haptics) persisted in UserDefaults —
//  separate from the per-playthrough game save.

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var musicOn: Bool { didSet { persist(); AudioManager.shared.apply(self); SoundManager.shared.applyMusicSettings() } }
    @Published var musicVolume: Double { didSet { persist(); AudioManager.shared.apply(self); SoundManager.shared.applyMusicSettings() } }
    @Published var sfxOn: Bool { didSet { persist() } }
    @Published var hapticsOn: Bool { didSet { persist() } }

    private let d = UserDefaults.standard

    private init() {
        musicOn     = d.object(forKey: "set_musicOn")     as? Bool   ?? true
        musicVolume = d.object(forKey: "set_musicVolume") as? Double ?? 0.5
        sfxOn       = d.object(forKey: "set_sfxOn")       as? Bool   ?? true
        hapticsOn   = d.object(forKey: "set_hapticsOn")   as? Bool   ?? true
    }

    private func persist() {
        d.set(musicOn, forKey: "set_musicOn")
        d.set(musicVolume, forKey: "set_musicVolume")
        d.set(sfxOn, forKey: "set_sfxOn")
        d.set(hapticsOn, forKey: "set_hapticsOn")
    }
}
