import Foundation
import Observation

// Watch-native prayer settings (persisted to the watch's own UserDefaults). This makes the
// watch STANDALONE — it can compute correct times without the phone. Phone→watch sync
// (WatchConnectivity) is a later layer that would adopt into this same store. Only the
// items that "fit" the wrist are editable here (method, madhab, fajr rule, alerts); the
// phone's set-once config (offsets, hijri, angle sub-methods, reciter) is left to sync.
@Observable
final class WatchPrayerSettings {
    static let shared = WatchPrayerSettings()

    private enum Keys {
        static let method = "wps.method"
        static let madhab = "wps.madhab"
        static let fajrRule = "wps.fajrRule"
        static let suhoor = "wps.suhoorReminder"
        static let alert = "wps.alert."      // + prayer name
    }

    var method: CalculationMethod {
        didSet { UserDefaults.standard.set(method.rawValue, forKey: Keys.method); WatchPrayerTimes.shared.recompute() }
    }
    var madhab: Madhab {
        didSet { UserDefaults.standard.set(madhab.rawValue, forKey: Keys.madhab); WatchPrayerTimes.shared.recompute() }
    }
    var fajrRule: WatchFajrRule {
        didSet { UserDefaults.standard.set(fajrRule.rawValue, forKey: Keys.fajrRule); WatchPrayerTimes.shared.recompute() }
    }
    var suhoorReminder: Bool {
        didSet { UserDefaults.standard.set(suhoorReminder, forKey: Keys.suhoor) }
    }

    private init() {
        let d = UserDefaults.standard
        method = CalculationMethod(rawValue: d.string(forKey: Keys.method) ?? "") ?? .muslimWorldLeague
        madhab = Madhab(rawValue: d.integer(forKey: Keys.madhab)) ?? .shafi   // 0 → nil → .shafi
        fajrRule = WatchFajrRule(rawValue: d.string(forKey: Keys.fajrRule) ?? "") ?? .normal
        suhoorReminder = d.bool(forKey: Keys.suhoor)
    }

    // MARK: - Per-prayer alerts (persisted; notification scheduling is a later layer)

    func isAlertEnabled(_ prayer: Prayer) -> Bool {
        UserDefaults.standard.bool(forKey: Keys.alert + "\(prayer)")
    }

    func setAlert(_ prayer: Prayer, _ on: Bool) {
        UserDefaults.standard.set(on, forKey: Keys.alert + "\(prayer)")
    }
}

// Watch copy of the iPhone FajrRule (app-side enum, not shared): master angle vs a fixed
// 1.5 h before sunrise. Kept 1:1 so a future sync can map straight across.
enum WatchFajrRule: String, CaseIterable, Identifiable {
    case normal
    case beforeSunrise
    var id: String { rawValue }
    var name: String { self == .normal ? "Normal (angle)" : "1.5 h before sunrise" }
}

extension CalculationMethod {
    /// Concise label for the watch method picker.
    var watchName: String {
        switch self {
        case .muslimWorldLeague:    "Muslim World League"
        case .egyptian:             "Egyptian"
        case .karachi:              "Karachi"
        case .ummAlQura:            "Umm al-Qura"
        case .dubai:                "Dubai"
        case .moonsightingCommittee:"Moonsighting"
        case .northAmerica:         "North America (ISNA)"
        case .kuwait:               "Kuwait"
        case .qatar:                "Qatar"
        case .singapore:            "Singapore"
        case .tehran:               "Tehran"
        case .turkey:               "Turkey"
        case .other:                "Other"
        }
    }
}
