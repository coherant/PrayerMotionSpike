import AVFoundation

@Observable
final class AudioManager {
    private(set) var isSpeaking: Bool = false

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    nonisolated(unsafe) private let delegate    = SpeechFinishDelegate()
    nonisolated(unsafe) private var player: AVAudioPlayer?
    nonisolated(unsafe) private let playerDelegate = PlayerFinishDelegate()

    init() { synthesizer.delegate = delegate }

    func configure(route: AudioRoute) {
        var options: AVAudioSession.CategoryOptions = .duckOthers
        if route == .speakerOnly { options.insert(.defaultToSpeaker) }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: options)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @MainActor
    func speak(_ text: String, language: Language = UserPreferences.shared.guidanceLanguage) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            isSpeaking = true
            delegate.onFinish = { [weak self] in
                self?.isSpeaking = false
                cont.resume()
            }
            let u = AVSpeechUtterance(string: text)
            u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            u.voice = AVSpeechSynthesisVoice(language: language.voiceCode)
            synthesizer.speak(u)
        }
    }

    /// Plays a recorded recitation, awaited to completion — the teacher leads, so the clip is
    /// never truncated by the caller's `.pace` pause regardless of length. Returns `false` if
    /// the file can't be loaded/started so the caller can fall back to TTS.
    @MainActor
    @discardableResult
    func play(_ url: URL) async -> Bool {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        player = p
        p.delegate = playerDelegate
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            isSpeaking = true
            playerDelegate.onFinish = { [weak self] in
                self?.isSpeaking = false
                cont.resume(returning: true)
            }
            if !p.play() {
                isSpeaking = false
                playerDelegate.onFinish = nil
                cont.resume(returning: false)
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        player?.stop()
    }
}

// MARK: - Audio clips
//
// Resolves a liturgical id to a bundled recording, or nil when none is installed (→ TTS
// fallback). Files are FLAT, uniquely-named resources — so synced-folder flattening is a
// feature, not a problem (no subfolders to preserve, no name collisions):
//   • in-salah recitation:  "<reciterId>-<language>-<P-id>.m4a"  (e.g. muallim-ai-ar-P-7.m4a)
//   • Muezzin call:          "<muezzinId>-<C-id>.m4a"            (e.g. bilal-C-1.m4a)
// Drop the files anywhere under the app's synced Resources; they bundle by name. Either
// .m4a or .caf is accepted (Muʿallim AI ships as .m4a, AAC). Missing clips are expected —
// partial sets just work, and anything absent falls back to TTS.
enum AudioClips {
    /// Active reciter id — driven by the setup screen's Voice picker
    /// (`UserPreferences.reciterId`; default `muallim-ai` = "Muʿallim AI", معلّم).
    static var reciterId: String { UserPreferences.shared.reciterId }

    /// Active guider id for guidance (I) — one guider for now, so a constant.
    /// `murshid-ai` = "Murshid AI" (مرشد), the voice that coaches the movements.
    static let guiderId = "murshid-ai"

    static func recitation(_ id: PrayerID,
                           reciterId: String = UserPreferences.shared.reciterId,
                           language: Language = UserPreferences.shared.recitationLanguage) -> URL? {
        // Flat key "<reciter>-<language>-<P-id>" (e.g. "muallim-ai-ar-P-7"). Missing →
        // nil → the caller's TTS fallback, so an Arabic-only reciter still works when
        // any language is picked.
        clip("\(reciterId)-\(language.rawValue)-\(id.rawValue)")
    }

    static func call(_ id: CallID, muezzinId: String) -> URL? {
        clip("\(muezzinId)-\(id.rawValue)")
    }

    /// Guidance audio by raw key — the clip basename after `<guider>-<lang>-`. The key is an
    /// instruction id ("I-24") or a niyet variant ("fajr-fard-I-25") → murshid-ai-en-… ; missing
    /// → nil → the caller's TTS fallback, exactly like recitation.
    static func guidance(_ key: String,
                         guiderId: String = AudioClips.guiderId,
                         language: Language = UserPreferences.shared.guidanceLanguage) -> URL? {
        clip("\(guiderId)-\(language.rawValue)-\(key)")
    }

    static func instruction(_ id: InstructionID,
                            language: Language = UserPreferences.shared.guidanceLanguage) -> URL? {
        guidance(id.rawValue, language: language)
    }

    // Accept .m4a (the Muʿallim AI set) or .caf. Names are globally unique, so we look in
    // the bundle root AND the likely preserved subfolders — covers both a synced folder
    // that flattens resources and one that keeps the `recitations/` (or `muezzin/`) path.
    private static let clipExtensions = ["m4a", "caf"]
    private static let clipSubdirs: [String?] = [nil, "recitations", "muezzin", "Resources/recitations"]

    private static func clip(_ name: String) -> URL? {
        for sub in clipSubdirs {
            for ext in clipExtensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                    return url
                }
            }
        }
        return nil
    }

#if DEBUG
    /// One-shot console report of which recitation/call clips are installed vs missing —
    /// printed at session start so populating the audio files is a matter of reading the list.
    static func logCoverage(muezzinId: String) {
        let recMissing  = PrayerID.allCases.filter { recitation($0) == nil }.map(\.rawValue)
        let callMissing = CallID.allCases.filter { call($0, muezzinId: muezzinId) == nil }.map(\.rawValue)
        let recHave  = PrayerID.allCases.count - recMissing.count
        let callHave = CallID.allCases.count - callMissing.count
        print("[AudioClips] recitations (\(reciterId)): \(recHave)/\(PrayerID.allCases.count)"
              + (recMissing.isEmpty ? " ✅ all installed" : " — missing: \(recMissing.joined(separator: ", "))"))
        print("[AudioClips] muezzin (\(muezzinId)): \(callHave)/\(CallID.allCases.count)"
              + (callMissing.isEmpty ? " ✅ all installed" : " — missing: \(callMissing.joined(separator: ", "))"))
    }
#endif
}

private final class SpeechFinishDelegate: NSObject, AVSpeechSynthesizerDelegate {
    nonisolated(unsafe) var onFinish: (() -> Void)?

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
}

private final class PlayerFinishDelegate: NSObject, AVAudioPlayerDelegate {
    nonisolated(unsafe) var onFinish: (() -> Void)?

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let fn = onFinish; onFinish = nil; fn?()
    }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let fn = onFinish; onFinish = nil; fn?()
    }
}
