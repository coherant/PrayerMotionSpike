import SwiftUI

// Standalone watchOS app. Stage 1 of the watch-core-extraction arc
// (docs/features/watch/REFACTOR-PLAN.md): the product motion + session parts
// lifted out of the WatchMotionSpike repo, standing ALONGSIDE the iPhone app —
// it does NOT touch SalahMotionCore yet (that seam is Stage 3/4). The spike's
// capture/export tooling (MotionLogger, MotionStreamer, ExportManager, Relay)
// and its telemetry screens (TelemetryView, PositionLabView) were deliberately
// left behind in the spike.
@main
struct SalahMotionWatchApp: App {
    @State private var motionManager = MotionManager()
    @State private var sessionManager = WorkoutSessionManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
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
