import Foundation

// MARK: - WeatherState
//
// The canonical (CORE) weather value for one instant — the boundary value the view
// layers render. No SwiftUI, no provider types. Temperatures are stored in CANONICAL
// °C; the display unit is a user preference (`TemperatureUnit`), converted at render
// time — keeping core unit-agnostic. See docs/features/weather/SPEC.md §2.

struct WeatherState: Equatable, Codable, Sendable {
    let condition: WeatherCondition
    let intensity: Double        // 0…1 — drives particle density / opacity
    let cloudCover: Double        // 0…1
    let precipChance: Double      // 0…1
    let tempNowC: Double          // canonical °C
    let tempHighC: Double
    let tempLowC: Double
    let isDaylight: Bool
    let asOf: Date                // for staleness / "as of" display
}

// MARK: - Temperature unit (display / user preference)

enum TemperatureUnit: String, Codable, Sendable, CaseIterable {
    case celsius
    case fahrenheit

    func value(fromCelsius c: Double) -> Double {
        switch self {
        case .celsius:    return c
        case .fahrenheit: return c * 9 / 5 + 32
        }
    }

    var symbol: String { self == .celsius ? "°C" : "°F" }
}

extension WeatherState {
    func temperatureNow(in unit: TemperatureUnit)  -> Int { Int(unit.value(fromCelsius: tempNowC).rounded()) }
    func temperatureHigh(in unit: TemperatureUnit) -> Int { Int(unit.value(fromCelsius: tempHighC).rounded()) }
    func temperatureLow(in unit: TemperatureUnit)  -> Int { Int(unit.value(fromCelsius: tempLowC).rounded()) }
}

// MARK: - Sample data (previews / tests / MockWeatherProvider)

extension WeatherState {
    /// Deterministic per-condition sample so previews can cycle every visual state.
    static func sample(_ condition: WeatherCondition = .clear,
                       isDaylight: Bool = true,
                       asOf: Date = Date()) -> WeatherState {
        let (cloud, precip): (Double, Double)
        switch condition {
        case .clear:        (cloud, precip) = (0.05, 0.0)
        case .partlyCloudy: (cloud, precip) = (0.40, 0.1)
        case .cloudy:       (cloud, precip) = (0.85, 0.2)
        case .fog:          (cloud, precip) = (0.70, 0.1)
        case .drizzle:      (cloud, precip) = (0.70, 0.5)
        case .rain:         (cloud, precip) = (0.85, 0.8)
        case .heavyRain:    (cloud, precip) = (0.95, 0.95)
        case .thunderstorm: (cloud, precip) = (0.95, 0.9)
        case .snow:         (cloud, precip) = (0.90, 0.8)
        case .sleet:        (cloud, precip) = (0.90, 0.8)
        case .hail:         (cloud, precip) = (0.90, 0.7)
        case .wind:         (cloud, precip) = (0.50, 0.2)
        }
        return WeatherState(
            condition: condition,
            intensity: condition.nominalIntensity,
            cloudCover: cloud,
            precipChance: precip,
            tempNowC: 18, tempHighC: 22, tempLowC: 12,
            isDaylight: isDaylight,
            asOf: asOf
        )
    }
}
