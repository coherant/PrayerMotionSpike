import Foundation
import SalahMotionCore

// App-side convenience init: injects the iPhone shell's seams — AirPods motion
// (HeadphoneMotionDetector) and audio guidance (AudioGuidanceRenderer) — into the
// core PrayerStateMachine. Existing call sites that don't specify a source/renderer
// resolve here, so the extraction stays source-compatible.
extension PrayerStateMachine {
    convenience init(sequence: [PrayerState] = GuidedSequenceGenerator.generate(),
                     guidanceLevel: GuidanceLevel = UserPreferences.shared.guidanceLevel,
                     participantName: String = "",
                     useDefaultThresholds: Bool = false) {
        self.init(sequence: sequence,
                  guidanceLevel: guidanceLevel,
                  participantName: participantName,
                  useDefaultThresholds: useDefaultThresholds,
                  motionSource: HeadphoneMotionDetector(),
                  renderer: AudioGuidanceRenderer())
    }
}
