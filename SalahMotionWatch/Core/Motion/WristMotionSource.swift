import Foundation
import CoreMotion
import SalahMotionCore

// The watch shell's MotionSource (Stage 4b/v3): wrist CMMotionManager driving
// PrayerStateMachine. Reports a full posture (classify() v3 on gravityZ + gravityX) so the
// machine matches it against each state's expected posture — meaning stand-up from sujūd
// gates on *standing*, not merely leaving the floor. Two axes because gravityZ alone can't
// split the two close pairs on a real wrist: Sujūd↔Jalsa and Takbīr↔Qiyām separate on gravityX.
//
// Calibration (second wrist, guided-capture 2026-07-01):
//   gz:  Ruku +0.42 | Qiyam -0.11 | Jalsa -0.58 | Sujud -0.65 | Takbir -0.13
//   gx:  Ruku +0.89 | Qiyam +0.52 | Jalsa +0.70 | Sujud +0.52 | Takbir -0.75
// Still few wrists — treat as tunable, not final.
@Observable
final class WristMotionSource: MotionSource {
    private let cm = CMMotionManager()
    private let queue = OperationQueue()

    // --- classify() v3 thresholds (tunable) ---
    private static let bowingGz: Double   =  0.15   // gz above → Rukūʿ
    private static let standingGz: Double = -0.35   // gz above (and below bowing) → standing
    // gz below standing: gx below → Sujūd, else Jalsa. Set to 0.65 — the clean gap between
    // Sujūd's gx range [0.48,0.61] and Jalsa's [0.68,0.74]. Was 0.61 (Sujūd's upper edge),
    // which clipped the settled 2nd sujūd to "sitting" so it never fired.
    private static let sujudGx: Double    =  0.65
    private static let takbirGx: Double   =  0.0    // gz in standing band but gx below → Takbīr (display only)

    private(set) var smoothedPitch: Double = 0
    private(set) var smoothedRoll:  Double = 0
    private(set) var smoothedYaw:   Double = 0
    private(set) var currentPosture: DetectedPosture? = nil
    private(set) var postureLabel: String? = nil     // 5-way incl. Takbīr, for the UI
    private(set) var gravityZ: Double = 0
    private(set) var gravityX: Double = 0
    var reportsPosture: Bool { true }

    // Movement latch — stands in for the taslīm head turns (the du'ā-raise after the final
    // sitting). A gyro pulse keeps isMoving true past the machine's ~1.5s hold window.
    private var lastMovementAt: Date = .distantPast
    private let moveThreshold: Double = 0.8   // rad/s
    private let movementLatch: Double = 3.0
    var isMoving: Bool { Date().timeIntervalSince(lastMovementAt) < movementLatch }

    // Takbīr (hands to ears — the opening) is unique to the wrist: negative gravityX while
    // roughly upright. Held briefly so it's a deliberate takbīratul-iḥrām, not a stray motion.
    // Used to START the prayer on the watch (see GuidedPrayerWatchView).
    var isTakbir: Bool { gravityX < Self.takbirGx && gravityZ > Self.standingGz }
    private var takbirStart: Date?
    private let takbirHold: Double = 0.6
    private(set) var takbirHeld: Bool = false

    var isAvailable: Bool { cm.isDeviceMotionAvailable }

    func start(onRawSample: (@MainActor @Sendable (Double, Double, Double) -> Void)? = nil) {
        guard cm.isDeviceMotionAvailable else { return }
        cm.stopDeviceMotionUpdates()   // safe re-start: the source runs on the idle screen (takbīr
                                       // detection), then PSM.start() re-attaches with its sample callback
        cm.deviceMotionUpdateInterval = 1.0 / 50.0
        cm.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let p = motion.attitude.pitch * 180 / .pi
            let r = motion.attitude.roll  * 180 / .pi
            let y = motion.attitude.yaw   * 180 / .pi
            let gz = motion.gravity.z
            let gx = motion.gravity.x
            let rot = motion.rotationRate
            let gyroMag = (rot.x * rot.x + rot.y * rot.y + rot.z * rot.z).squareRoot()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.smoothedPitch = p
                self.smoothedRoll  = r
                self.smoothedYaw   = y
                self.gravityZ = gz
                self.gravityX = gx
                self.currentPosture = Self.posture(gz: gz, gx: gx)
                self.postureLabel   = Self.label(gz: gz, gx: gx)
                if gyroMag > self.moveThreshold { self.lastMovementAt = Date() }
                // Held-takbīr detection (to start the prayer).
                if self.isTakbir {
                    if self.takbirStart == nil { self.takbirStart = Date() }
                    if Date().timeIntervalSince(self.takbirStart!) >= self.takbirHold { self.takbirHeld = true }
                } else {
                    self.takbirStart = nil
                    self.takbirHeld = false
                }
                onRawSample?(p, r, y)
            }
        }
    }

    func stop() { cm.stopDeviceMotionUpdates() }

    // 2D classify → the posture the machine gates on. Takbīr shares Qiyām's gz, so it maps to
    // .standing (harmless — the opening doesn't gate on posture); it's split out only for display.
    static func posture(gz: Double, gx: Double) -> DetectedPosture {
        if gz > bowingGz   { return .bowing }        // Rukūʿ
        if gz > standingGz { return .standing }      // Qiyām (and Takbīr)
        return gx < sujudGx ? .prostration : .sitting // Sujūd (low gx) vs Jalsa (high gx)
    }

    static func label(gz: Double, gx: Double) -> String {
        if gz > bowingGz   { return "Ruku" }
        if gx < takbirGx   { return "Takbir" }        // hands to ears — distinctive negative gx
        if gz > standingGz { return "Qiyam" }
        return gx < sujudGx ? "Sujud" : "Jalsa"
    }
}
