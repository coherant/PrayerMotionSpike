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
    func speak(_ text: String, language: Language = UserPreferences.shared.language) async {
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
// fallback). Two voices, two folders:
//   • in-salah recitation:  recitations/<reciterId>/<P-id>.m4a   (e.g. recitations/default/P-7.m4a)
//   • Muezzin call:          muezzin/<muezzinId>/<C-id>.m4a       (e.g. muezzin/bilal/C-1.m4a)
// Add each folder to the app target as a FOLDER REFERENCE so the per-voice subdirectories are
// preserved in the bundle. Missing clips are expected — drop files in incrementally; partial
// sets just work, and anything absent falls back to TTS.
enum AudioClips {
    /// Active reciter folder for in-salah recitation. Defaults until a reciter picker is wired.
    static var reciterId: String = "default"

    static func recitation(_ id: PrayerID, reciterId: String = AudioClips.reciterId) -> URL? {
        clip(id.rawValue, in: "recitations/\(reciterId)")
    }

    static func call(_ id: CallID, muezzinId: String) -> URL? {
        clip(id.rawValue, in: "muezzin/\(muezzinId)")
    }

    private static func clip(_ name: String, in subdir: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: subdir)
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
