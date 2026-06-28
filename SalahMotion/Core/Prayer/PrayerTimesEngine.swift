import Foundation
import CoreLocation
import Observation

// MARK: - Prayer times engine
//
// Source of truth for the day's prayer times. Wraps the vendored Adhan library
// (Core/Prayer/Adhan) and computes the five daily times + sunrise + Qiyam from a
// coordinate, the current date, and PrayerCalculationSettings.
//
// PrayerTime.scheduledDate / .displayTime read from `shared` (falling back to
// fixed times only before the first computation), so the whole app gets real
// times without each call site knowing about the engine.
//
// Times are absolute `Date` instants (Adhan computes in UTC); display them with
// a locale/timezone-aware DateFormatter. Comparisons against `Date()` are correct
// as-is.

@Observable
final class PrayerTimesEngine {
    static let shared = PrayerTimesEngine()

    /// Melbourne, Australia — where SalahMotion was made. Used until the device
    /// reports a real location, so times are sensible from launch. 🇦🇺
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
    static let defaultTimeZone = TimeZone(identifier: "Australia/Melbourne") ?? .current

    private(set) var coordinate = PrayerTimesEngine.defaultCoordinate
    /// Timezone of the current location. Prayer instants are absolute UTC, so this
    /// is what renders/schedules them at the location's wall-clock time.
    private(set) var timeZone = PrayerTimesEngine.defaultTimeZone
    private(set) var usingDeviceLocation = false

    /// Today's computed times, keyed by prayer. Empty only if computation failed.
    private(set) var times: [PrayerTime: Date] = [:]
    private(set) var sunrise: Date?
    /// Start of the last third of the night — the recommended time for Qiyam.
    private(set) var qiyam: Date?

    /// The calendar day `times` were computed for (start of day, local).
    private(set) var computedForDay: Date?

    private init() {
        // Seed from the last device location so a cold launch renders the real
        // place on the FIRST frame — Melbourne stays only as the genuine first-run
        // fallback. Without this, every launch briefly computes at Melbourne and
        // then jumps when CoreLocation reports (a visible stutter in the celestial
        // arc near a horizon crossing, and wrong prayer times for a beat).
        if let saved = Self.loadSavedLocation() {
            coordinate = saved.coordinate
            timeZone = saved.timeZone
            usingDeviceLocation = true
        }
        recompute()
    }

    // MARK: - Inputs

    /// Update to the device's real coordinate and recompute.
    func setCoordinate(_ coord: CLLocationCoordinate2D) {
        coordinate = coord
        usingDeviceLocation = true
        Self.saveLocation(coordinate: coord)
        recompute()
    }

    /// Update to the location's timezone (from reverse-geocoding) and recompute,
    /// so times render/schedule at the location's wall-clock time.
    func setTimeZone(_ tz: TimeZone) {
        Self.saveLocation(timeZone: tz)
        guard tz != timeZone else { return }
        timeZone = tz
        recompute()
    }

    // MARK: - Last-known-location persistence

    private enum DefaultsKey {
        static let latitude = "engine.lastLatitude"
        static let longitude = "engine.lastLongitude"
        static let timeZone = "engine.lastTimeZoneID"
    }

    /// The remembered device coordinate + timezone, or nil if never resolved.
    /// Both must be present — a coordinate without its timezone would render the
    /// place at the wrong wall-clock time.
    private static func loadSavedLocation() -> (coordinate: CLLocationCoordinate2D, timeZone: TimeZone)? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: DefaultsKey.latitude) != nil,
              let tzID = defaults.string(forKey: DefaultsKey.timeZone),
              let tz = TimeZone(identifier: tzID) else { return nil }
        let coord = CLLocationCoordinate2D(
            latitude: defaults.double(forKey: DefaultsKey.latitude),
            longitude: defaults.double(forKey: DefaultsKey.longitude))
        return (coord, tz)
    }

    private static func saveLocation(coordinate: CLLocationCoordinate2D? = nil,
                                     timeZone: TimeZone? = nil) {
        let defaults = UserDefaults.standard
        if let coordinate {
            defaults.set(coordinate.latitude, forKey: DefaultsKey.latitude)
            defaults.set(coordinate.longitude, forKey: DefaultsKey.longitude)
        }
        if let timeZone {
            defaults.set(timeZone.identifier, forKey: DefaultsKey.timeZone)
        }
    }

    /// Recompute if the calendar day has rolled over (call from a periodic timer).
    func refreshIfNeeded(now: Date = Date()) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let day = cal.startOfDay(for: now)
        if computedForDay != day { recompute(now: now) }
    }

    // MARK: - Computation

    func recompute(now: Date = Date()) {
        let settings = PrayerCalculationSettings.shared
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)

        var params = settings.method.params
        params.madhab = settings.madhab
        params.adjustments = settings.prayerAdjustments

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: now)

        guard let pt = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else {
            // Keep any previous values rather than wiping to fixed times.
            return
        }

        times = [
            .fajr:    pt.fajr,
            .dhuhr:   pt.dhuhr,
            .asr:     pt.asr,
            .maghrib: pt.maghrib,
            .isha:    pt.isha,
        ]
        sunrise = pt.sunrise

        // Fajr override: a fixed 1.5h before sunrise, plus any user Fajr offset.
        if settings.fajrRule == .beforeSunrise {
            let off = settings.offsets[.fajr] ?? 0
            times[.fajr] = pt.sunrise.addingTimeInterval(TimeInterval(-90 * 60 + off * 60))
        }

        qiyam = SunnahTimes(from: pt)?.lastThirdOfTheNight
        computedForDay = cal.startOfDay(for: now)

        // Times just changed (location, settings, or day rollover) — keep the
        // scheduled prayer notifications in sync. No-op unless already authorized.
        NotificationManager.refreshIfAuthorized()
    }

    // MARK: - Queries

    /// The absolute instant of `prayer` today, or nil before the first compute.
    func date(for prayer: PrayerTime) -> Date? { times[prayer] }

    /// PURE: times + sunrise for ANY date, WITHOUT mutating engine state or
    /// rescheduling notifications. Used by DayTheme and the time-machine egg so
    /// they can read arbitrary days safely (the egg must never touch live state).
    func computeTimes(for date: Date) -> DayPrayerTimes? {
        let settings = PrayerCalculationSettings.shared
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var params = settings.method.params
        params.madhab = settings.madhab
        params.adjustments = settings.prayerAdjustments

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let pt = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else {
            return nil
        }
        var t: [PrayerTime: Date] = [
            .fajr: pt.fajr, .dhuhr: pt.dhuhr, .asr: pt.asr, .maghrib: pt.maghrib, .isha: pt.isha,
        ]
        if settings.fajrRule == .beforeSunrise {
            let off = settings.offsets[.fajr] ?? 0
            t[.fajr] = pt.sunrise.addingTimeInterval(TimeInterval(-90 * 60 + off * 60))
        }
        return DayPrayerTimes(times: t, sunrise: pt.sunrise)
    }

    /// PURE: the sun-altitude anchors that drive the atmospheric theme timeline
    /// (DayTheme §10). Same Meeus astronomy as the prayer times, via
    /// `SolarTime.timeForSolarAngle`, so colours and times never drift apart.
    /// Returns nil at latitudes/seasons where an angle never occurs (polar).
    func twilightAnchors(for date: Date) -> TwilightAnchors? {
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let solar = SolarTime(date: comps, coordinates: coords) else { return nil }

        let utc = Calendar.gregorianUTC
        func angle(_ degrees: Double, afterTransit: Bool) -> Date? {
            solar.timeForSolarAngle(Angle(degrees), afterTransit: afterTransit)
                .flatMap { utc.date(from: $0) }
        }
        guard
            let sunrise          = utc.date(from: solar.sunrise),
            let sunset           = utc.date(from: solar.sunset),
            let astronomicalDawn = angle(-18, afterTransit: false),
            let nauticalDawn     = angle(-12, afterTransit: false),
            let morningGold      = angle(6,   afterTransit: false),
            let eveningGold      = angle(6,   afterTransit: true),
            let civilDusk        = angle(-6,  afterTransit: true),
            let nauticalDusk     = angle(-12, afterTransit: true),
            let astronomicalDusk = angle(-18, afterTransit: true)
        else { return nil }

        return TwilightAnchors(
            astronomicalDawn: astronomicalDawn,
            nauticalDawn: nauticalDawn,
            sunrise: sunrise,
            morningGold: morningGold,
            eveningGold: eveningGold,
            sunset: sunset,
            civilDusk: civilDusk,
            nauticalDusk: nauticalDusk,
            astronomicalDusk: astronomicalDusk
        )
    }
}

/// Sun-altitude anchors for one day (value type; no side effects). Times are
/// absolute instants. See docs/design-reference/theme.md §10.
struct TwilightAnchors {
    let astronomicalDawn: Date  // sun −18° before transit (true dawn)
    let nauticalDawn: Date      // −12°
    let sunrise: Date           // 0° (−50′)
    let morningGold: Date       // +6° after sunrise (golden hour ends → full day)
    let eveningGold: Date       // +6° before sunset (golden hour begins)
    let sunset: Date            // 0°
    let civilDusk: Date         // −6°
    let nauticalDusk: Date      // −12°
    let astronomicalDusk: Date  // −18° after transit (full night)
}

/// A day's computed prayer times + sunrise (value type; no side effects).
struct DayPrayerTimes {
    let times: [PrayerTime: Date]
    let sunrise: Date?
}
