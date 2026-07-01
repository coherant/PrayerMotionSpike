// swift-tools-version: 5.9
import PackageDescription

// SalahMotionCore — the shell-agnostic guided-prayer engine, extracted in the
// watch-core-extraction arc (docs/features/watch/REFACTOR-PLAN.md, Stage 3).
// Pure logic only: no UIKit / AVFoundation / CoreMotion / HealthKit. Consumed by
// both the iPhone app and the standalone watch app; talks to each shell through
// the MotionSource (IN) and GuidanceEvent (OUT) seams.
//
// watchOS 10 / iOS 17 floors: the Observation framework (@Observable, used by
// UserPreferences) requires them.
let package = Package(
    name: "SalahMotionCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "SalahMotionCore", targets: ["SalahMotionCore"])
    ],
    targets: [
        .target(name: "SalahMotionCore")
    ]
)
