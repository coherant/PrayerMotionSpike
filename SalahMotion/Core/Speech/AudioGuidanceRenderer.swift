import Foundation
import AudioToolbox
import SalahMotionCore

// Audio route (source: docs/global-configurations.md). An audio-shell concern, so it
// lives here with the renderer rather than in the core state machine.
enum AudioRoute {
    case speakerOnly  // forces built-in speaker even when AirPods connected
    case headphones   // routes to AirPods if connected, speaker otherwise (default)
    case auto         // iOS decides — same as headphones in practice
}

// The iPhone shell's GuidanceRenderer: maps semantic GuidanceEvents to audio via
// AudioManager. This is the clip→TTS→language logic lifted verbatim out of
// PrayerStateMachine (Stage 3b OUT-seam) — behaviour is preserved by moving it here
// rather than changing it. The watch will supply a haptic renderer instead.
@MainActor
final class AudioGuidanceRenderer: GuidanceRenderer {
    private let audioManager = AudioManager()

    init(route: AudioRoute = .headphones) {
        audioManager.configure(route: route)
    }

    var isSpeaking: Bool { audioManager.isSpeaking }
    func stop() { audioManager.stop() }

    func render(_ event: GuidanceEvent) async {
        switch event {
        case .line(let line):   await renderLine(line)
        case .utterance(let u): await renderUtterance(u)
        case .call(let id):     await renderCall(id)
        case .cue:              AudioServicesPlaySystemSound(1108)
        }
    }

    /// Voices one prayer line: plays its recorded recitation clip if installed (awaited to
    /// completion — the teacher leads, never truncated), otherwise falls back to TTS of the
    /// rendered text. A missing clip is expected (recordings land incrementally); empty text
    /// is a no-op.
    private func renderLine(_ line: PrayerLine) async {
        if let id = line.clipID {
            if let url = AudioClips.recitation(id) {
                #if DEBUG
                print("[AudioClips] ▶︎ recitation \(id.rawValue) → \(url.lastPathComponent)")
                #endif
                if await audioManager.play(url) { return }
                #if DEBUG
                print("[AudioClips] ⚠️ recitation \(id.rawValue) — clip found but failed to play → TTS")
                #endif
            } else {
                #if DEBUG
                print("[AudioClips] ⚠️ recitation \(id.rawValue) (reciter=\(AudioClips.reciterId), "
                      + "lang=\(UserPreferences.shared.recitationLanguage.rawValue)) — no clip found → TTS")
                #endif
            }
        } else if let key = line.audioKey {
            let lang = UserPreferences.shared.guidanceLanguage
            if let url = AudioClips.guidance(key, language: lang) {
                #if DEBUG
                print("[AudioClips] ▶︎ guidance \(key) → \(url.lastPathComponent)")
                #endif
                if await audioManager.play(url) { return }
                #if DEBUG
                print("[AudioClips] ⚠️ guidance \(key) — clip found but failed to play → TTS")
                #endif
            } else {
                #if DEBUG
                print("[AudioClips] ⚠️ guidance \(key) (lang=\(lang.rawValue)) — no clip found → TTS")
                #endif
            }
        }
        if !line.utterance.isEmpty {
            let ttsLang = line.audioKey != nil ? UserPreferences.shared.guidanceLanguage
                                               : UserPreferences.shared.recitationLanguage
            await audioManager.speak(line.utterance, language: ttsLang)
        }
    }

    /// Voices a non-prayer line (entry / exit / reprompt): plays the recorded clip for its
    /// id if installed (awaited to completion), else TTS — guidance in the guidance language
    /// (instruction clip), recitation in the recitation language (recitation clip).
    private func renderUtterance(_ u: Utterance) async {
        switch u {
        case .guidance(let id):
            let lang = UserPreferences.shared.guidanceLanguage
            if let url = AudioClips.instruction(id, language: lang) {
                #if DEBUG
                print("[AudioClips] ▶︎ guidance \(id.rawValue) → \(url.lastPathComponent)")
                #endif
                if await audioManager.play(url) { return }
                #if DEBUG
                print("[AudioClips] ⚠️ guidance \(id.rawValue) — clip found but failed to play → TTS")
                #endif
            } else {
                #if DEBUG
                print("[AudioClips] ⚠️ guidance \(id.rawValue) (lang=\(lang.rawValue)) — no clip → TTS")
                #endif
            }
            await audioManager.speak(InstructionLibrary.text(id, lang), language: lang)
        case .recitation(let id):
            let lang = UserPreferences.shared.recitationLanguage
            if let url = AudioClips.recitation(id, language: lang) {
                #if DEBUG
                print("[AudioClips] ▶︎ recitation \(id.rawValue) → \(url.lastPathComponent)")
                #endif
                if await audioManager.play(url) { return }
                #if DEBUG
                print("[AudioClips] ⚠️ recitation \(id.rawValue) — clip found but failed to play → TTS")
                #endif
            } else {
                #if DEBUG
                print("[AudioClips] ⚠️ recitation \(id.rawValue) (lang=\(lang.rawValue)) — no clip → TTS")
                #endif
            }
            await audioManager.speak(PrayerLibrary.text(id, lang), language: lang)
        case .plain(let s):
            guard !s.isEmpty else { return }
            await audioManager.speak(s, language: UserPreferences.shared.guidanceLanguage)
        }
    }

    /// Voices the container call: the Muezzin's recorded Arabic clip if installed (awaited
    /// to completion), else TTS of the Arabic call text. The Muezzin is Arabic-only,
    /// independent of the guidance & recitation languages.
    private func renderCall(_ id: CallID) async {
        if let url = AudioClips.call(id, muezzinId: UserPreferences.shared.muezzinId),
           await audioManager.play(url) {
            return
        }
        #if DEBUG
        print("[AudioClips] ⚠️ call \(id.rawValue) (muezzin=\(UserPreferences.shared.muezzinId)) — TTS fallback")
        #endif
        let text = CallLibrary.text(id, .arabic)
        guard !text.isEmpty else { return }
        await audioManager.speak(text, language: .arabic)
    }
}
