// SalahMotionCore — shell-agnostic guided-prayer engine.
//
// Stage 3a-i: package skeleton + XcodeGen/SPM plumbing only. This placeholder
// exists so the iPhone app and the watch app can declare the dependency and we
// can prove both link against the package before any code moves in.
//
// Next (3a-ii): move the pure guided-engine closure in — PrayerSequence
// (PrayerState / MotionTrigger / Utterance / GuidedSequenceGenerator), SalatType,
// the Language libraries, MotionThresholds, calibration — behavior-preserving,
// golden snapshot green.
public enum SalahMotionCore {
    public static let version = "0.1.0-skeleton"
}
