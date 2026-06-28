import CoreLocation

// MARK: - CachedWeatherProvider
//
// Wraps any WeatherProvider with the persisted (gridCell, timeWindow) cache. This is
// where the 6h window lives — one call per cell per window, regardless of how many
// times the screen asks. Swap the upstream (WeatherKit → Open-Meteo → proxy) freely.
// See docs/features/weather/SPEC.md §2–§3.

struct CachedWeatherProvider: WeatherProvider {
    let upstream: any WeatherProvider
    let cache: WeatherCache
    let window: TimeInterval
    let gridResolution: Double

    init(upstream: any WeatherProvider,
         cache: WeatherCache = WeatherCache(),
         window: TimeInterval = 6 * 3600,   // 6h (SPEC-locked default)
         gridResolution: Double = 0.1) {     // ~10km grid cell
        self.upstream = upstream
        self.cache = cache
        self.window = window
        self.gridResolution = gridResolution
    }

    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState {
        let key = WeatherCacheKey.make(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            date: date,
            window: window,
            gridResolution: gridResolution
        )
        if let hit = await cache.value(for: key) { return hit }
        let fresh = try await upstream.weather(for: location, on: date)
        await cache.store(fresh, for: key)
        return fresh
    }
}
