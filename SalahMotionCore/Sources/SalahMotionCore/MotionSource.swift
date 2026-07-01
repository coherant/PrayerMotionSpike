import Foundation

/// A body posture a source can detect directly (the wrist, via classify()). The machine
/// matches this against each state's `expectedPosture`, so it can require *standing* vs
/// *sitting* — a distinction the coarse `MotionTrigger.upright` can't make.
public enum DetectedPosture: Equatable, Sendable {
    case standing, bowing, sitting, prostration
}

// The IN seam (docs/features/watch/REFACTOR-PLAN.md Stage 3b). PrayerStateMachine
// consumes motion through this protocol instead of a hard-wired sensor, so each shell
// injects its own source: iPhone = AirPods (HeadphoneMotionDetector), watch = wrist
// (CMMotionManager), or a scripted test source. Behavior-preserving shape: the raw
// pitch/roll/yaw stream the machine already reads today (degrees). A richer
// posture-transition source can layer on later without changing this contract.
public protocol MotionSource: AnyObject {
    var isAvailable: Bool { get }
    var smoothedPitch: Double { get }
    var smoothedRoll: Double { get }
    var smoothedYaw: Double { get }
    /// Begin updates. `onRawSample` fires per raw sample with (pitch, roll, yaw) in degrees,
    /// delivered on the main actor (so the machine can update its @Observable state directly).
    func start(onRawSample: (@MainActor @Sendable (Double, Double, Double) -> Void)?)
    func stop()

    /// The posture transition this source currently detects, if it runs its own detection
    /// (e.g. the wrist, via classify() on gravityZ). `nil` → the machine falls back to its own
    /// pitch/roll/yaw threshold detection (e.g. AirPods / head geometry). Default `nil`, so a
    /// raw-stream source needs no change.
    var currentTrigger: MotionTrigger? { get }

    /// True when the wrist is in deliberate motion (not a settled hold). Used to stand in for
    /// the taslīm head turns, which a wrist source can't sense: the natural du'ā-raise after
    /// the final sitting registers as movement and closes the prayer. Default `false`.
    var isMoving: Bool { get }

    /// Whether this source reports a full posture (wrist) vs only the raw stream (AirPods).
    /// When true, the machine matches `currentPosture` against each state's expected posture
    /// instead of the coarse trigger, and skips the head-geometry sit→stand timed bridge.
    var reportsPosture: Bool { get }
    /// The posture the source currently detects (wrist), or nil. Default nil.
    var currentPosture: DetectedPosture? { get }
}

public extension MotionSource {
    var currentTrigger: MotionTrigger? { nil }
    var isMoving: Bool { false }
    var reportsPosture: Bool { false }
    var currentPosture: DetectedPosture? { nil }
}
