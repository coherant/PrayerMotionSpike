import CoreLocation
import WeatherKit

// MARK: - WeatherKitProvider
//
// The live data source. Fetches only the `.current` + `.daily` datasets (cheaper)
// and maps them onto the canonical `WeatherState`. Requires the WeatherKit
// capability/entitlement at RUNTIME (Apple Developer portal + target Signing &
// Capabilities) and the mandatory attribution link. Compiles and its mapping is
// testable WITHOUT the entitlement; only the network fetch needs it.
// See docs/features/weather/SPEC.md §2, §6.

struct WeatherKitProvider: WeatherProvider {
    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState {
        // `date` is unused: WeatherKit returns the live current conditions; the
        // CachedWeatherProvider keys by date-window, so freshness is handled there.
        let (current, daily) = try await WeatherService.shared.weather(
            for: location, including: .current, .daily
        )
        let today = daily.first

        func celsius(_ m: Measurement<UnitTemperature>) -> Double { m.converted(to: .celsius).value }

        let condition = SalahMotion.WeatherCondition(current.condition)
        let nowC = celsius(current.temperature)
        return WeatherState(
            condition: condition,
            intensity: condition.nominalIntensity,
            cloudCover: current.cloudCover,
            precipChance: today?.precipitationChance ?? 0,
            tempNowC: nowC,
            tempHighC: today.map { celsius($0.highTemperature) } ?? nowC,
            tempLowC: today.map { celsius($0.lowTemperature) } ?? nowC,
            isDaylight: current.isDaylight,
            asOf: current.date
        )
    }
}

// MARK: - Condition mapping (WeatherKit → canonical)
//
// Collapses WeatherKit's ~40 conditions onto our 12. `default` handles unmapped /
// future (`@unknown`) cases — the enum is non-frozen — falling back to `.cloudy`.

extension SalahMotion.WeatherCondition {
    init(_ wk: WeatherKit.WeatherCondition) {
        switch wk {
        case .clear, .mostlyClear, .hot:
            self = .clear
        case .partlyCloudy, .mostlyCloudy:
            self = .partlyCloudy
        case .cloudy, .smoky, .haze:
            self = .cloudy
        case .foggy:
            self = .fog
        case .drizzle, .sunShowers:
            self = .drizzle
        case .rain:
            self = .rain
        case .heavyRain:
            self = .heavyRain
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms, .hurricane, .tropicalStorm:
            self = .thunderstorm
        case .snow, .heavySnow, .flurries, .blizzard, .blowingSnow,
             .sunFlurries, .frigid, .wintryMix:
            self = .snow
        case .sleet, .freezingRain, .freezingDrizzle:
            self = .sleet
        case .hail:
            self = .hail
        case .windy, .breezy, .blowingDust:
            self = .wind
        default:
            self = .cloudy
        }
    }
}

// MARK: - Provider factory
//
// Single place the "Mock-by-default in DEBUG" decision lives (SPEC §3). DEBUG uses
// the mock — ZERO real calls while developing — unless the `ff.weatherLive`
// UserDefaults switch is set to test live data. Release always uses WeatherKit.
// Both are wrapped in the persisted 6h cache.

enum WeatherProviderFactory {
    static func make() -> any WeatherProvider {
        #if DEBUG
        let useLive = UserDefaults.standard.bool(forKey: "ff.weatherLive")
        let upstream: any WeatherProvider = useLive ? WeatherKitProvider() : MockWeatherProvider()
        return CachedWeatherProvider(upstream: upstream)
        #else
        return CachedWeatherProvider(upstream: WeatherKitProvider())
        #endif
    }
}
