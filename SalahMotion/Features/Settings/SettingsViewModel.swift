import Foundation
import StoreKit
import UIKit
import Observation

// MARK: - Settings view model
// Source of truth: docs/features/settings/SPEC.md + docs/features/settings/settings.html
//
// Drives the themed master/detail Settings flow. Wires the controls that have a
// real backend to the persisted singletons:
//   • PrayerCalculationSettings.shared — method, Fajr rule, Asr madhab, offsets, Hijri
//   • UserPreferences.shared           — language
//   • NotificationManager              — per-prayer alerts + Suhoor reminder
//
// Controls without a backend yet (Sunrise/Doha, Isha rule, Qiyam-in-list,
// per-prayer recitation) are present in the UI per the mockup and persist their
// selection locally, but do not yet affect the engine/audio. See SPEC for status.

enum SettingsScreen {
    case main, alerts, advanced
}

/// Which Advanced "Prayer Methods" row is expanded (only one at a time).
enum AdvancedMethodRow: Hashable {
    case calculation, fajr, sunrise, asr, isha
}

/// Isha derivation (UI-only for now — "before" wording mirrors the mockup).
enum IshaRuleUI: String, CaseIterable, Identifiable {
    case normal, before15, before2h
    var id: String { rawValue }
    var label: String {
        switch self {
        case .normal:   return "Normal"
        case .before15: return "1.5 hrs before Maghrib"
        case .before2h: return "2 hrs before Maghrib"
        }
    }
    var desc: String {
        switch self {
        case .normal:   return "Use the master time"
        case .before15: return "Earlier onset"
        case .before2h: return "Latest calculation"
        }
    }
}

/// A selectable Adhan reciter (display-only catalogue from the mockup).
struct Reciter: Identifiable, Equatable {
    let id: String
    let name: String
    let arabic: String

    static let all: [Reciter] = [
        Reciter(id: "mishary",  name: "Mishary Alafasy",           arabic: "مشاري العفاسي"),
        Reciter(id: "sudais",   name: "Abd al-Rahman al-Sudais",   arabic: "عبدالرحمن السديس"),
        Reciter(id: "minshawi", name: "Mohamed al-Minshawi",       arabic: "محمد المنشاوي"),
        Reciter(id: "hussary",  name: "Mahmoud Khalil al-Hussary", arabic: "محمود خليل الحصري"),
        Reciter(id: "ghamdi",   name: "Saad al-Ghamdi",            arabic: "سعد الغامدي"),
        Reciter(id: "shuraym",  name: "Saud al-Shuraym",           arabic: "سعود الشريم"),
    ]
}

@Observable
final class SettingsViewModel {

    let calc  = PrayerCalculationSettings.shared
    let prefs = UserPreferences.shared

    // MARK: - Navigation / expansion state

    var screen: SettingsScreen = .main
    var expandedAlertPrayer: PrayerTime? = nil
    var expandedMethodRow: AdvancedMethodRow? = nil

    // MARK: - Wired notification state (mirrored — NotificationManager isn't @Observable)

    var alertEnabled: [PrayerTime: Bool] = [:]

    var suhoorReminder: Bool {
        didSet { NotificationManager.setSuhoorEnabled(suhoorReminder) }
    }

    // MARK: - UI-only state (persisted locally, not yet wired to the engine/audio)

    var sunriseDoha: Bool {
        didSet { UserDefaults.standard.set(sunriseDoha, forKey: Keys.sunriseDoha) }
    }
    var ishaRule: IshaRuleUI {
        didSet { UserDefaults.standard.set(ishaRule.rawValue, forKey: Keys.ishaRule) }
    }
    var qiyamOn: Bool {
        didSet { UserDefaults.standard.set(qiyamOn, forKey: Keys.qiyamOn) }
    }
    var reciters: [PrayerTime: String] {
        didSet { persistReciters() }
    }

    init() {
        let d = UserDefaults.standard
        suhoorReminder = NotificationManager.isSuhoorEnabled()
        alertEnabled = Dictionary(uniqueKeysWithValues:
            PrayerTime.allCases.map { ($0, NotificationManager.isEnabled($0)) })

        sunriseDoha = d.bool(forKey: Keys.sunriseDoha)
        ishaRule = IshaRuleUI(rawValue: d.string(forKey: Keys.ishaRule) ?? "") ?? .normal
        qiyamOn = d.bool(forKey: Keys.qiyamOn)
        let rawReciters = d.dictionary(forKey: Keys.reciters) as? [String: String] ?? [:]
        reciters = Dictionary(uniqueKeysWithValues: rawReciters.compactMap { key, value in
            PrayerTime(rawValue: key).map { ($0, value) }
        })
    }

    // MARK: - Navigation

    func go(to screen: SettingsScreen) {
        self.screen = screen
    }

    func goBack() {
        screen = .main
        expandedAlertPrayer = nil
        expandedMethodRow = nil
    }

    // MARK: - Per-prayer alerts (wired)

    func isAlertEnabled(_ prayer: PrayerTime) -> Bool { alertEnabled[prayer] ?? false }

    func setAlert(_ enabled: Bool, for prayer: PrayerTime) {
        if NotificationManager.isEnabled(prayer) != enabled {
            NotificationManager.toggle(prayer)
        }
        alertEnabled[prayer] = NotificationManager.isEnabled(prayer)
    }

    func toggleExpandedAlert(_ prayer: PrayerTime) {
        expandedAlertPrayer = (expandedAlertPrayer == prayer) ? nil : prayer
    }

    // MARK: - Per-prayer recitation (UI-only)

    func reciter(for prayer: PrayerTime) -> String { reciters[prayer] ?? "mishary" }

    func setReciter(_ id: String, for prayer: PrayerTime) { reciters[prayer] = id }

    // MARK: - Advanced method expansion

    func toggleExpandedMethod(_ row: AdvancedMethodRow) {
        expandedMethodRow = (expandedMethodRow == row) ? nil : row
    }

    // MARK: - Per-prayer time offsets (wired)

    func offset(for prayer: PrayerTime) -> Int { calc.offsets[prayer] ?? 0 }

    func adjustOffset(_ delta: Int, for prayer: PrayerTime) {
        let next = (calc.offsets[prayer] ?? 0) + delta
        guard (-30...30).contains(next) else { return }
        calc.offsets[prayer] = next
    }

    func offsetLabel(for prayer: PrayerTime) -> String {
        let value = offset(for: prayer)
        return value == 0 ? "0 min" : String(format: "%+d min", value)
    }

    // MARK: - Hijri offset (wired)

    func adjustHijri(_ delta: Int) {
        let next = calc.hijriOffsetDays + delta
        guard (-3...3).contains(next) else { return }
        calc.hijriOffsetDays = next
    }

    var hijriLabel: String {
        let days = calc.hijriOffsetDays
        if days == 0 { return "0 days" }
        return String(format: "%+d day%@", days, abs(days) == 1 ? "" : "s")
    }

    // MARK: - Rate this app (wired)

    func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    // MARK: - Persistence helpers

    private func persistReciters() {
        let dict = Dictionary(uniqueKeysWithValues: reciters.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(dict, forKey: Keys.reciters)
    }

    private enum Keys {
        static let sunriseDoha = "settings.sunriseDoha"
        static let ishaRule    = "settings.ishaRule"
        static let qiyamOn     = "settings.qiyamOn"
        static let reciters    = "settings.reciters"
    }
}
