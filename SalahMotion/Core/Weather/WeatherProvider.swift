import CoreLocation

// MARK: - WeatherProvider
//
// The swap point. Every data source (WeatherKit now; Open-Meteo / a server proxy
// later) hides behind this, so changing provider — or how cost scales — never
// touches the cache or the views. `Sendable` so it composes with the cache actor.
// See docs/features/weather/SPEC.md §2.

protocol WeatherProvider: Sendable {
    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState
}

// MARK: - MockWeatherProvider
//
// Deterministic, network-free. The DEBUG / Previews default, so the entire UI and
// visual system get built and reviewed with ZERO real WeatherKit calls (SPEC §3).

struct MockWeatherProvider: WeatherProvider {
    let state: WeatherState
    init(_ state: WeatherState = .sample()) { self.state = state }
    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState { state }
}
