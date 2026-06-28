import Foundation
import Observation
import CoreLocation

// MARK: - WeatherStore
//
// View-facing holder for the current `WeatherState`. Builds its provider via the
// factory (Mock in DEBUG, WeatherKit in release — both behind the 6h cache), so a
// refresh is at most one network call per cell/window. Weather is ambient: a failed
// fetch keeps the last good value and never blocks the screen.
// See docs/features/weather/SPEC.md §2, §5.

@MainActor
@Observable
final class WeatherStore {
    private(set) var state: WeatherState?

    private let provider: any WeatherProvider = WeatherProviderFactory.make()

    func refresh(latitude: Double, longitude: Double, now: Date = Date()) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            state = try await provider.weather(for: location, on: now)
        } catch {
            // Ambient layer — keep the last good state, never surface an error.
        }
    }

    // MARK: Manual cycle (dev / demo)
    //
    // Tap the weather capsule to step through every condition, starting at sunny
    // (`.clear`). This drives the chip today; the real fetched `state` above is the
    // production path, wired to the view later. `allCases` order begins at `.clear`.

    var manualCondition: WeatherCondition = .clear
    var displayState: WeatherState { .sample(manualCondition) }

    func cycleManual() {
        let all = WeatherCondition.allCases
        let i = all.firstIndex(of: manualCondition) ?? 0
        manualCondition = all[(i + 1) % all.count]
    }
}
