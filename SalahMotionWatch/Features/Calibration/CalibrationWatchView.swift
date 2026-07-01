import SwiftUI

// Placeholder — on-wrist calibration (per-user classify() thresholds). Real content
// lands when we add the guided posture capture on-device (docs/features/watch).
struct CalibrationWatchView: View {
    var body: some View {
        ContentUnavailableView("Calibration", systemImage: "slider.horizontal.3",
                               description: Text("Coming soon"))
            .navigationTitle("Calibration")
    }
}
