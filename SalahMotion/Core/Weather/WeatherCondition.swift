import Foundation

// MARK: - WeatherCondition
//
// The app's canonical weather vocabulary — the visual system keys off THIS, never a
// provider's raw condition type (so swapping WeatherKit ↔ Open-Meteo ↔ proxy never
// touches the views). Providers map their conditions onto these cases at the boundary.
// See docs/features/weather/SPEC.md §2.

enum WeatherCondition: String, CaseIterable, Codable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case heavyRain
    case thunderstorm
    case snow
    case sleet
    case hail
    case wind
}

extension WeatherCondition {
    /// Baseline 0…1 for particle density / effect strength. A real, uniform precip
    /// intensity isn't available across every provider, so severity-by-condition is
    /// the robust canonical source (used by both the provider and `.sample`).
    var nominalIntensity: Double {
        switch self {
        case .clear, .partlyCloudy, .cloudy: return 0.0
        case .wind:                          return 0.2
        case .fog, .drizzle:                 return 0.3
        case .rain, .snow:                   return 0.6
        case .sleet:                         return 0.7
        case .hail:                          return 0.8
        case .heavyRain, .thunderstorm:      return 1.0
        }
    }
}
