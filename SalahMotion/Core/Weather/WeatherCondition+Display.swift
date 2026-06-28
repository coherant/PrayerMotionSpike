import Foundation

// MARK: - WeatherCondition display
//
// Human label + SF Symbol per condition (day/night aware for clear & partly cloudy).
// Strings only — no SwiftUI — so it's reusable and testable.

extension WeatherCondition {
    func label(isDaylight: Bool) -> String {
        switch self {
        case .clear:        return isDaylight ? "Sunny" : "Clear"
        case .partlyCloudy: return "Partly cloudy"
        case .cloudy:       return "Cloudy"
        case .fog:          return "Fog"
        case .drizzle:      return "Drizzle"
        case .rain:         return "Rain"
        case .heavyRain:    return "Heavy rain"
        case .thunderstorm: return "Storm"
        case .snow:         return "Snow"
        case .sleet:        return "Sleet"
        case .hail:         return "Hail"
        case .wind:         return "Windy"
        }
    }

    func symbolName(isDaylight: Bool) -> String {
        switch self {
        case .clear:        return isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy:       return "cloud.fill"
        case .fog:          return "cloud.fog.fill"
        case .drizzle:      return "cloud.drizzle.fill"
        case .rain:         return "cloud.rain.fill"
        case .heavyRain:    return "cloud.heavyrain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow:         return "cloud.snow.fill"
        case .sleet:        return "cloud.sleet.fill"
        case .hail:         return "cloud.hail.fill"
        case .wind:         return "wind"
        }
    }
}
