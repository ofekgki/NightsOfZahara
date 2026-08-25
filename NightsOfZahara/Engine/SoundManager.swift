//  File-based audio: a looping background music track and short one-shot
//  sound effects tied to actions. Music obeys the user's music setting;
//  effects obey the SFX setting. Every call is defensively guarded so a
//  missing file or audio failure never affects gameplay.


import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    /// The action sound effects, keyed to their bundled file names.
    enum SFX: String {
        case coins    = "coins"        // Work — the clink of earned coin
        case treasure = "tresure"      // Treasure found while searching
        case door     = "doorOpen_1"   // Entering the shop / making a connection
        case palace   = "palace"       // Approaching Sinbad's palace
    }

    private var backgroundPlayer: AVAudioPlayer?
    /// Preloaded one-shot players, one per effect (retained so they aren't
    /// deallocated mid-playback).
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    private init() {}

    // MARK: - Session

    private func configureSession() {
        guard !sessionConfigured else { return }
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
        sessionConfigured = true
    }

    private func url(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "m4a")
    }

    // MARK: - Background music

    /// Start the looping background track (idempotent).
    func startBackground() {
        configureSession()
        if backgroundPlayer == nil, let url = url(for: "background") {
            backgroundPlayer = try? AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1     // loop forever
            backgroundPlayer?.prepareToPlay()
        }
        applyMusicSettings()
    }

    /// Sync the background track's volume / on-off with the user's settings.
    func applyMusicSettings() {
        let s = AppSettings.shared
        guard let player = backgroundPlayer else { return }
        player.volume = s.musicOn ? Float(s.musicVolume) : 0
        if s.musicOn {
            if !player.isPlaying { player.play() }
        } else {
            player.pause()
        }
    }

    func stopBackground() {
        backgroundPlayer?.stop()
    }

    // MARK: - One-shot effects

    /// Play a sound effect once (gated by the SFX setting).
    func play(_ effect: SFX) {
        guard AppSettings.shared.sfxOn else { return }
        configureSession()

        // Reuse a preloaded player per effect; restart it from the top so
        // repeated actions retrigger the sound cleanly.
        if let existing = effectPlayers[effect.rawValue] {
            existing.currentTime = 0
            existing.play()
            return
        }
        guard let url = url(for: effect.rawValue),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        effectPlayers[effect.rawValue] = player
        player.play()
    }
}
