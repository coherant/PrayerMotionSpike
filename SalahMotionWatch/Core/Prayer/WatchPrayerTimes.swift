import Foundation
import CoreLocation
import Observation

// Minimal watch-side prayer-times engine, computed on the wrist from the shared Adhan calc
// (no network). Location defaults to Melbourne until on-wrist CoreLocation lands; params
// default to Muslim World League / Shafiʿi (matching the iPhone defaults). Recomputes on
// demand and on calendar-day rollover — the calc is cheap, so nothing is persisted.
@Observable
final class WatchPrayerTimes {
    var coordinate = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)  // Melbourne default 🇦🇺

    private(set) var pt: PrayerTimes?
    private(set) var computedForDay: Date?

    /// The five obligatory prayers in order, with today's instants.
    var ordered: [(prayer: Prayer, date: Date)] {
        guard let pt else { return [] }
        return [.fajr, .dhuhr, .asr, .maghrib, .isha].map { ($0, pt.time(for: $0)) }
    }

    var nextPrayer: Prayer? { pt?.nextPrayer() }
    var nextPrayerDate: Date? { nextPrayer.map { pt!.time(for: $0) } }

    var qiblaDirection: Double {
        Qibla(coordinates: Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)).direction
    }

    func refreshIfNeeded(now: Date = Date()) {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = .current
        if computedForDay != cal.startOfDay(for: now) { recompute(now: now) }
    }

    func recompute(now: Date = Date()) {
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var params = CalculationMethod.muslimWorldLeague.params
        params.madhab = .shafi

        var cal = Calendar(identifier: .gregorian); cal.timeZone = .current
        let comps = cal.dateComponents([.year, .month, .day], from: now)

        guard let computed = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else { return }
        pt = computed
        computedForDay = cal.startOfDay(for: now)
    }
}
