import Foundation
import Observation

// MARK: - Nature animation settings
// Source of truth: docs/features/settings/SPEC.md §2 (Nature Animation)
//
// User-facing toggles for the ambient nature layers painted into the Prayer Times
// sky. Persisted to UserDefaults; PrayerTimesView reads these and renders each layer
// only when its toggle is on. Default ON — the animations ship enabled.
//
// Weather is additionally gated by FeatureFlags.weather (the dev/go-to-market gate):
// the user toggle only has effect once that flag is on.

@Observable
final class NatureSettings {
    static let shared = NatureSettings()

    /// Ambient sky birds (SkyBirdsView).
    var birds: Bool {
        didSet { UserDefaults.standard.set(birds, forKey: Keys.birds) }
    }

    /// Night meteors / shooting stars (NightMeteorsView).
    var asteroids: Bool {
        didSet { UserDefaults.standard.set(asteroids, forKey: Keys.asteroids) }
    }

    /// Live weather painted into the sky (WeatherLayerView). Also gated by FeatureFlags.weather.
    var weather: Bool {
        didSet { UserDefaults.standard.set(weather, forKey: Keys.weather) }
    }

    /// Aurora glow over the night sky (AuroraView).
    var aurora: Bool {
        didSet { UserDefaults.standard.set(aurora, forKey: Keys.aurora) }
    }

    private init() {
        let d = UserDefaults.standard
        birds     = d.object(forKey: Keys.birds)     as? Bool ?? true
        asteroids = d.object(forKey: Keys.asteroids) as? Bool ?? true
        weather   = d.object(forKey: Keys.weather)   as? Bool ?? true
        aurora    = d.object(forKey: Keys.aurora)    as? Bool ?? true
    }

    private enum Keys {
        static let birds     = "nature.birds"
        static let asteroids = "nature.asteroids"
        static let weather   = "nature.weather"
        static let aurora    = "nature.aurora"
    }
}
