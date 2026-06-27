import Foundation
import Observation

// MARK: - Time-machine egg (hidden)
//
// A purely VISUAL rewind: it drives a `offset` added to "now" for the time-
// reactive UI (theme + celestial), animating 0 → −N days → 0 with an
// accelerate-then-decelerate curve, then snapping back. It never mutates the
// prayer engine or reschedules notifications — read-only illusion only.

/// ── TUNABLES ───────────────────────────────────────────────────────────────
/// Adjust these to dial in the animation. `legDuration` is the one-number speed
/// knob; the two weights set the accel/decel feel (only their ratio matters).
enum TimeMachineConfig {
    /// How far back the rewind travels, in days.
    static var daysBack: Double = 1

    /// Seconds for ONE direction (back, or forward). Round-trip = 2 × this.
    /// ← the main "speed" knob.
    static var legDuration: TimeInterval = 10

    /// Shape of each leg: time spent accelerating vs decelerating to a stop.
    /// Relative weights (your "3 accelerate, 2 decelerate") — only the ratio counts.
    static var accelerateWeight: Double = 3
    static var decelerateWeight: Double = 2
}

@MainActor
@Observable
final class TimeMachine {
    static let shared = TimeMachine()
    private init() {}

    /// Seconds added to "now" for all time-reactive UI. 0 = real time.
    private(set) var offset: TimeInterval = 0
    private(set) var isRunning = false

    private var task: Task<Void, Never>?

    /// Run the full round-trip rewind (back then forward). No-op if already running.
    func play() {
        guard !isRunning else { return }
        isRunning = true

        let leg = TimeMachineConfig.legDuration
        let total = leg * 2
        let maxBack = -TimeMachineConfig.daysBack * 86_400
        let start = Date()

        task = Task { @MainActor in
            while true {
                let elapsed = Date().timeIntervalSince(start)
                if elapsed >= total { break }
                offset = Self.offset(forElapsed: elapsed, leg: leg, maxBack: maxBack)
                try? await Task.sleep(nanoseconds: 16_000_000)   // ~60 fps
            }
            offset = 0
            isRunning = false
        }
    }

    // MARK: - Curve

    private static func offset(forElapsed elapsed: TimeInterval,
                               leg: TimeInterval, maxBack: Double) -> TimeInterval {
        if elapsed < leg {
            return maxBack * ease(elapsed / leg)              // 0 → maxBack
        } else {
            return maxBack * (1 - ease((elapsed - leg) / leg)) // maxBack → 0
        }
    }

    /// Accelerate-then-decelerate easing with a tunable split — the integral of a
    /// triangular velocity profile that peaks at `a` and returns to rest at 1.
    /// ease(0)=0, ease(1)=1.
    private static func ease(_ p: Double) -> Double {
        let total = TimeMachineConfig.accelerateWeight + TimeMachineConfig.decelerateWeight
        let a = max(0.001, min(0.999, TimeMachineConfig.accelerateWeight / total))
        if p <= a {
            return (p * p) / a
        } else {
            return a + 2.0 / (1 - a) * ((p - p * p / 2) - (a - a * a / 2))
        }
    }
}
