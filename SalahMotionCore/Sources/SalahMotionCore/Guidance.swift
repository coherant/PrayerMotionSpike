import Foundation

// The OUT seam — Option A (docs/features/watch/REFACTOR-PLAN.md Stage 3b). The state
// machine emits SEMANTIC guidance events and awaits their completion; each shell renders
// them its own way (iPhone = audio via AudioManager, watch = haptics, silent = instant).
// The core owns WHAT to guide; the shell owns HOW. The event payloads already carry the
// semantic role (Utterance is .recitation/.guidance/.plain), so a shell can fan out by role.

public enum GuidanceEvent {
    case line(PrayerLine)      // an in-position recitation line
    case utterance(Utterance)  // entry / exit / reprompt / instruction
    case call(CallID)          // Muezzin container call (Arabic)
    case cue                   // feedback tick (iPhone: system sound; watch: haptic)
}

@MainActor
public protocol GuidanceRenderer: AnyObject {
    /// Render the event, returning only when it has completed — so guided-mode timing
    /// (audio-completion pacing) survives. A silent or haptic shell may return instantly.
    func render(_ event: GuidanceEvent) async
    /// Whether speech is currently playing (drives UI state).
    var isSpeaking: Bool { get }
    func stop()
}
