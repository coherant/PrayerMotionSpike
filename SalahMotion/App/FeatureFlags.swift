import Foundation

// MARK: - FeatureFlags
//
// Single source of truth for in-development feature gates. A flag OFF means the
// feature is byte-for-byte absent at runtime — no UI, no network, no cost.
//
// Weather (docs/features/weather/SPEC.md): the nature-fusion layer — live weather
// painted into the time-of-day sky alongside the celestial arc and birds, plus the
// day's temperature beside the prayer times. Gated here until the staged build is
// ready and the go-to-market (free/paid/price) is decided.

enum FeatureFlags {

    /// Weather fusion feature. OFF until the staged build (SPEC §6) lands and
    /// pricing/packaging is settled. Flip `weatherDefault` to enable for everyone,
    /// or set the `ff.weather` UserDefaults key (a hidden Settings dev-toggle) to
    /// flip it on a device without a rebuild.
    static var weather: Bool {
        UserDefaults.standard.object(forKey: Key.weather) as? Bool ?? weatherDefault
    }

    // DEV: ON while building/reviewing the weather feature. Set back to `false`
    // before release until the staged build is complete and go-to-market is decided.
    private static let weatherDefault = true

    private enum Key {
        static let weather = "ff.weather"
    }
}
