import SwiftUI

// Standalone watchOS app running SalahMotionCore. "Guided Prayer" drives a
// PrayerStateMachine from the wrist (WristMotionSource) and renders it on the watch
// (WatchGuidanceRenderer), phone-free. Prayer Times and Calibration are placeholders
// for now (docs/features/watch/REFACTOR-PLAN.md).
@main
struct SalahMotionWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
        }
    }
}
