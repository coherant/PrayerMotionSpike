import Foundation

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
}

public extension MotionSource {
    var currentTrigger: MotionTrigger? { nil }
}
