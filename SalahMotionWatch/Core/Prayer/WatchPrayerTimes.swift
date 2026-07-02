import Foundation
import CoreLocation
import Observation

// Minimal watch-side prayer-times engine, computed on the wrist from the shared Adhan calc
// (no network). Location defaults to Melbourne until on-wrist CoreLocation lands; params
// default to Muslim World League / Shafiʿi (matching the iPhone defaults). Recomputes on
// demand and on calendar-day rollover — the calc is cheap, so nothing is persisted.
@Observable
final class WatchPrayerTimes {
    static let shared = WatchPrayerTimes()

    private(set) var coordinate = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)  // Melbourne default 🇦🇺
    private(set) var timeZone: TimeZone = .current

    private(set) var pt: PrayerTimes?
    private(set) var computedForDay: Date?

    /// Update to a live device fix (from WatchLocationManager) and recompute.
    func setCoordinate(_ coord: CLLocationCoordinate2D) {
        coordinate = coord
        recompute()
    }

    /// Update to the location's timezone (from reverse-geocoding) so times render at its
    /// wall-clock time, and recompute.
    func setTimeZone(_ tz: TimeZone) {
        timeZone = tz
        recompute()
    }

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

    // MARK: - Up-next + day rail (same behaviour as the iPhone PrayerTimesViewModel)

    /// Node-fraction positions of the five prayers along the rail.
    static let railNodeFractions: [Double] = [0.05, 0.38, 0.56, 0.72, 0.90]

    /// The prayer the "Up next" card tracks + the instant to count down to: the next prayer
    /// whose 15-minute window hasn't elapsed (so a prayer still reads "now" through its window);
    /// once every window has passed (Isha → dawn) it wraps to tomorrow's Fajr.
    func upNext(at moment: Date) -> (prayer: Prayer, date: Date)? {
        let times = ordered
        guard let fajr = times.first else { return nil }
        if let hit = times.first(where: { moment < $0.date.addingTimeInterval(15 * 60) }) {
            return hit
        }
        return (fajr.prayer, fajr.date.addingTimeInterval(24 * 60 * 60))
    }

    /// Countdown copy: "in Xh YYm" / "in Ym" / "now" (within the window).
    func countdown(at moment: Date) -> String {
        guard let up = upNext(at: moment) else { return "" }
        let interval = up.date.timeIntervalSince(moment)
        guard interval > 0 else { return "now" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60, minutes = totalMinutes % 60
        return hours > 0 ? "in \(hours)h \(String(format: "%02d", minutes))m" : "in \(minutes)m"
    }

    /// Index of the current/up-next prayer: the first whose time hasn't occurred yet; once
    /// Isha has passed it stays on Isha through the night (rail resets at the day rollover).
    func currentPrayerIndex(at moment: Date) -> Int {
        let times = ordered
        guard !times.isEmpty else { return 0 }
        return times.firstIndex(where: { $0.date > moment }) ?? (times.count - 1)
    }

    /// Continuous 0…1 rail fill, anchored to the real prayer instants: 0 at start of day,
    /// each prayer's node fraction at its real time, 1.0 at midnight; interpolated between.
    func continuousRailFill(at moment: Date) -> Double {
        let times = ordered
        guard times.count == 5 else { return 0 }
        var cal = Calendar(identifier: .gregorian); cal.timeZone = timeZone
        let startOfDay = cal.startOfDay(for: moment)
        let endOfDay = startOfDay.addingTimeInterval(24 * 60 * 60)

        var anchors: [(date: Date, fill: Double)] = [(startOfDay, 0.0)]
        for (i, item) in times.enumerated() { anchors.append((item.date, Self.railNodeFractions[i])) }
        anchors.append((endOfDay, 1.0))

        for k in 0..<(anchors.count - 1) {
            let a = anchors[k], b = anchors[k + 1]
            guard moment >= a.date && moment < b.date else { continue }
            let span = b.date.timeIntervalSince(a.date)
            guard span > 0 else { return a.fill }
            return a.fill + (moment.timeIntervalSince(a.date) / span) * (b.fill - a.fill)
        }
        return 1.0
    }

    func refreshIfNeeded(now: Date = Date()) {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = timeZone
        if computedForDay != cal.startOfDay(for: now) { recompute(now: now) }
    }

    func recompute(now: Date = Date()) {
        let coords = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var params = CalculationMethod.muslimWorldLeague.params
        params.madhab = .shafi

        var cal = Calendar(identifier: .gregorian); cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: now)

        guard let computed = PrayerTimes(coordinates: coords, date: comps, calculationParameters: params) else { return }
        pt = computed
        computedForDay = cal.startOfDay(for: now)
    }
}
