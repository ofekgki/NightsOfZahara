//
//  AudioManager.swift
//  Nights Of Zahara
//
//  Procedural background music — no audio files required. A gentle looping
//  arpeggio on an Arabian "Hijaz" scale plus a low drone, synthesized with
//  AVAudioEngine. Each area (mood) uses a different scale/tempo. All calls
//  are defensively guarded so audio failure never affects gameplay.
//

import AVFoundation

enum MusicMood {
    case city, palace, dungeon, shop, victory, title

    /// Note frequencies (Hz) for a short evocative phrase, and seconds-per-note.
    var voice: AudioManager.Voice {
        switch self {
        case .title:
            return .init(notes: [220.00, 233.08, 277.18, 293.66, 277.18, 233.08],
                         root: 110.0, noteDuration: 0.85)
        case .city:   // Hijaz on D
            return .init(notes: [293.66, 311.13, 369.99, 392.00, 415.30, 392.00, 369.99, 311.13],
                         root: 146.83, noteDuration: 0.55)
        case .palace: // stately, slower
            return .init(notes: [261.63, 311.13, 349.23, 392.00, 349.23, 311.13],
                         root: 130.81, noteDuration: 0.75)
        case .dungeon: // darker, lower
            return .init(notes: [196.00, 207.65, 246.94, 261.63, 246.94, 207.65],
                         root: 98.00, noteDuration: 0.6)
        case .shop:   // light, quick
            return .init(notes: [349.23, 415.30, 440.00, 466.16, 440.00, 415.30],
                         root: 174.61, noteDuration: 0.42)
        case .victory:
            return .init(notes: [392.00, 440.00, 523.25, 587.33, 523.25, 440.00],
                         root: 196.00, noteDuration: 0.5)
        }
    }
}

final class AudioManager {
    static let shared = AudioManager()

    struct Voice {
        var notes: [Double]
        var root: Double
        var noteDuration: Double
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100

    // Read from the audio render thread — kept simple (word-sized) on purpose.
    private var voice: Voice = MusicMood.title.voice
    private var gain: Double = 0.0            // master gain (0 = silent)
    private var sampleClock: Double = 0

    private var started = false
    private var enabled = true

    private init() {}

    // MARK: - Public API

    func startIfNeeded() {
        guard !started else { return }
        configureSession()
        buildGraph()
        do {
            try engine.start()
            started = true
        } catch {
            started = false   // silently give up; game is unaffected
        }
        apply(AppSettings.shared)
    }

    func setMood(_ mood: MusicMood) {
        voice = mood.voice
    }

    /// Sync master gain / on-off with the user's settings.
    func apply(_ settings: AppSettings) {
        enabled = settings.musicOn
        gain = settings.musicOn ? settings.musicVolume * 0.18 : 0.0
    }

    func stop() {
        engine.stop()
        started = false
    }

    // MARK: - Setup

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    private func buildGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let v = self.voice
            let g = self.gain
            let notesPerLoop = max(1, v.notes.count)
            let samplesPerNote = v.noteDuration * self.sampleRate

            for frame in 0..<Int(frameCount) {
                let clock = self.sampleClock + Double(frame)
                let t = clock / self.sampleRate

                // Which note in the phrase, and how far into it (for the envelope).
                let noteIndex = Int(clock / samplesPerNote) % notesPerLoop
                let intoNote = (clock.truncatingRemainder(dividingBy: samplesPerNote)) / samplesPerNote
                // Soft pluck envelope: quick attack, gentle decay.
                let env = pow(1.0 - intoNote, 1.6) * min(1.0, intoNote * 12.0)

                let melody = sin(2.0 * .pi * v.notes[noteIndex] * t) * 0.6 * env
                // Slow drone with a subtle vibrato for an "endless desert" feel.
                let vibrato = 1.0 + 0.004 * sin(2.0 * .pi * 0.15 * t)
                let drone = sin(2.0 * .pi * v.root * vibrato * t) * 0.28
                let fifth = sin(2.0 * .pi * v.root * 1.5 * t) * 0.12

                let sample = Float((melody + drone + fifth) * g)

                for buffer in ablPointer {
                    let buf = UnsafeMutableBufferPointer<Float>(buffer)
                    buf[frame] = sample
                }
            }
            self.sampleClock += Double(frameCount)
            return noErr
        }
        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }
}
