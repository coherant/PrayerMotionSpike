import SwiftUI

// Standalone watchOS app. Stage 4 (docs/features/watch/REFACTOR-PLAN.md): the app now
// runs SalahMotionCore — "Guided Prayer" drives a PrayerStateMachine from the wrist
// (WristMotionSource) and renders it on the watch (WatchGuidanceRenderer), phone-free.
// The remaining screens (Session, State Machine) are spike-derived motion scaffolding,
// kept for now for on-wrist inspection.
@main
struct SalahMotionWatchApp: App {
    @State private var motionManager = MotionManager()
    @State private var sessionManager = WorkoutSessionManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    NavigationLink("Guided Prayer") { GuidedPrayerWatchView() }
                    NavigationLink("Session") { WorkoutSessionView() }
                    NavigationLink("State Machine") { StateMachineView() }
                }
                .navigationTitle("SalahMotion")
            }
            .environment(motionManager)
            .environment(sessionManager)
        }
    }
}
