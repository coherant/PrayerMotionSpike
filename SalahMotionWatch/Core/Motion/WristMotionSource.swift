import Foundation
import CoreMotion
import SalahMotionCore

// The watch shell's MotionSource (Stage 4b): wrist CMMotionManager driving PrayerStateMachine.
// Unlike the iPhone's AirPods source (which hands raw pitch/roll/yaw to the machine's head-
// calibrated thresholds), the wrist runs its OWN detection — classify() v2 on gravityZ, which
// the spike showed cleanly separates the postures where wrist pitch/roll couldn't — and reports
// `currentTrigger` so the machine trusts it directly (see MotionSource.currentTrigger).
@Observable
final class WristMotionSource: MotionSource {
    private let cm = CMMotionManager()
    private let queue = OperationQueue()

    private(set) var smoothedPitch: Double = 0
    private(set) var smoothedRoll:  Double = 0
    private(set) var smoothedYaw:   Double = 0
    private(set) var currentTrigger: MotionTrigger? = nil
    /// Display-friendly posture label for the UI ("Qiyam"/"Ruku"/…), nil until first sample.
    private(set) var postureLabel: String? = nil

    var isAvailable: Bool { cm.isDeviceMotionAvailable }

    func start(onRawSample: (@MainActor @Sendable (Double, Double, Double) -> Void)? = nil) {
        guard cm.isDeviceMotionAvailable else { return }
        cm.deviceMotionUpdateInterval = 1.0 / 50.0
        cm.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let p = motion.attitude.pitch * 180 / .pi
            let r = motion.attitude.roll  * 180 / .pi
            let y = motion.attitude.yaw   * 180 / .pi
            let gz = motion.gravity.z
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.smoothedPitch = p
                self.smoothedRoll  = r
                self.smoothedYaw   = y
                self.currentTrigger = Self.trigger(forGravityZ: gz)
                self.postureLabel   = Self.posture(forGravityZ: gz)
                onRawSample?(p, r, y)
            }
        }
    }

    func stop() { cm.stopDeviceMotionUpdates() }

    // classify() v2 — derived from guided capture (docs/features/watch/REFACTOR-PLAN.md Stage 2).
    // gravityZ: Ruku +0.50 | Qiyam -0.11 | Jalsa -0.56 | Sujud -0.66. The machine waits on
    // transitions, so Qiyam and Jalsa (both "upright") collapse to .upright; posture is
    // disambiguated by sequence position inside the machine.
    // NOTE: single-user / settled-holds thresholds — pending cross-user validation.
    static func trigger(forGravityZ gz: Double) -> MotionTrigger? {
        if gz >  0.20 { return .ruku }
        if gz < -0.61 { return .sujood }   // Sujud
        return .upright                    // Qiyam / Jalsa
    }

    static func posture(forGravityZ gz: Double) -> String {
        if gz >  0.20 { return "Ruku" }
        if gz < -0.61 { return "Sujud" }
        if gz < -0.35 { return "Jalsa" }
        return "Qiyam"
    }
}
