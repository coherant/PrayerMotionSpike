import SwiftUI

// Standalone watchOS app running SalahMotionCore. "Guided Prayer" drives a
// PrayerStateMachine from the wrist (WristMotionSource) and renders it on the watch
// (WatchGuidanceRenderer), phone-free. Prayer Times and Calibration are placeholders
// for now (docs/features/watch/REFACTOR-PLAN.md).
@main
struct SalahMotionWatchApp: App {
    // Register the custom fonts (Cormorant Garamond / Manrope / Amiri) once at launch —
    // same families + registrar as the iPhone app (SalahMotionApp.init).
    init() { FontRegistrar.registerAll() }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
        }
    }
}
