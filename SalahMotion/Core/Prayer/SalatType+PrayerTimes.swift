import Foundation
import SalahMotionCore

// App-side bridge from the guided-engine SalatType to the prayer-times / adhan
// domain (PrayerTime, PrayerTimesEngine). Kept out of SalahMotionCore so the core
// stays free of the prayer-times feature.
extension SalatType {

    var prayerTime: PrayerTime {
        switch self {
        case .fajr:    return .fajr
        case .dhuhr:   return .dhuhr
        case .asr:     return .asr
        case .maghrib: return .maghrib
        case .isha:    return .isha
        }
    }

    /// The prayer whose *valid window* contains `now`, from real engine times.
    /// Windows: Fajr `[fajr, sunrise)` · Dhuhr `[dhuhr, asr)` · Asr `[asr, maghrib)` ·
    /// Maghrib `[maghrib, isha)` · Isha `[isha, next fajr)`.
    /// Special cases: Isha stays valid all night until 1 s before Fajr; the gap
    /// between sunrise (end of Fajr's time) and Dhuhr resolves to Dhuhr.
    /// Falls back to `.maghrib` only before the engine's first computation.
    static func current(now: Date = Date()) -> SalatType {
        let engine = PrayerTimesEngine.shared
        engine.refreshIfNeeded(now: now)   // ensure today's times across a day rollover

        guard
            let fajr    = engine.date(for: .fajr),
            let dhuhr   = engine.date(for: .dhuhr),
            let asr     = engine.date(for: .asr),
            let maghrib = engine.date(for: .maghrib),
            let isha    = engine.date(for: .isha)
        else {
            return .maghrib
        }
        let sunrise = engine.sunrise ?? dhuhr

        // Night — after today's Isha, or before today's Fajr (Isha extends to Fajr).
        if now >= isha || now < fajr { return .isha }
        // Fajr's valid time ends at sunrise.
        if now < sunrise  { return .fajr }
        // Sunrise→Dhuhr gap and the Dhuhr window both show Dhuhr.
        if now < asr      { return .dhuhr }
        if now < maghrib  { return .asr }
        return .maghrib
    }
}
