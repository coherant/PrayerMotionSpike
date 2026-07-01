import Foundation
import AVFoundation
import WatchKit
import SalahMotionCore

// The watch shell's GuidanceRenderer (Stage 4a). Maps the core's semantic GuidanceEvents
// to wrist output: a haptic for cues, and awaited TTS for spoken lines (watch speaker or
// paired AirPods) so guided-mode pacing survives. In silent mode the core emits few spoken
// events (the body is the clock), so this is mostly haptic; guided mode speaks.
@MainActor
final class WatchGuidanceRenderer: NSObject, GuidanceRenderer {
    private let synth = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synth.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    var isSpeaking: Bool { synth.isSpeaking }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        resume()   // don't leave an awaiting render() suspended forever
    }

    func render(_ event: GuidanceEvent) async {
        switch event {
        case .cue:
            WKInterfaceDevice.current().play(.click)
        case .line(let line):
            // Recitation line; guidance-keyed lines speak in the guidance language, else recitation.
            let lang = line.audioKey != nil ? UserPreferences.shared.guidanceLanguage
                                            : UserPreferences.shared.recitationLanguage
            await speak(line.utterance, lang)
        case .utterance(let u):
            switch u {
            case .guidance:
                WKInterfaceDevice.current().play(.directionUp)   // an instruction to move — haptic + speak
                await speak(u.text(in: UserPreferences.shared.guidanceLanguage),
                            UserPreferences.shared.guidanceLanguage)
            case .recitation:
                await speak(u.text(in: UserPreferences.shared.recitationLanguage),
                            UserPreferences.shared.recitationLanguage)
            case .plain(let s):
                await speak(s, UserPreferences.shared.guidanceLanguage)
            }
        case .call(let id):
            await speak(CallLibrary.text(id, .arabic), .arabic)
        }
    }

    private func speak(_ text: String, _ language: Language) async {
        guard !text.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            self.continuation = c
            let u = AVSpeechUtterance(string: text)
            u.voice = AVSpeechSynthesisVoice(language: language.voiceCode)
            synth.speak(u)
        }
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }
}

extension WatchGuidanceRenderer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        Task { @MainActor in self.resume() }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        Task { @MainActor in self.resume() }
    }
}
