import Foundation
import Observation

/// Spoken guidance voice timbre (Murshid → I). SPEC §2 "Spoken AI Voice".
/// Persisted preference; not yet bound to a concrete TTS voice (UI present — not wired).
enum VoiceGender: String, CaseIterable, Identifiable {
    case masculine, feminine
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .masculine: return "Masculine"
        case .feminine:  return "Feminine"
        }
    }
}

@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    // De-conflated language axes: guidance (Murshid → I instructions) and recitation
    // (Muʿallim → P) are independent. Muezzin calls (C) are Arabic-only, not stored here.
    var guidanceLanguage: Language {
        didSet { UserDefaults.standard.set(guidanceLanguage.rawValue, forKey: Keys.guidanceLanguage) }
    }
    var recitationLanguage: Language {
        didSet { UserDefaults.standard.set(recitationLanguage.rawValue, forKey: Keys.recitationLanguage) }
    }
    /// Selected reciter (Muʿallim → recitation P). Default = Muʿallim AI.
    var reciterId: String {
        didSet { UserDefaults.standard.set(reciterId, forKey: Keys.reciter) }
    }
    /// Transitional single-language alias (reads recitation; sets BOTH). Lets the
    /// pre-split UI compile until the setup screen exposes the two pickers (Stage 2).
    var language: Language {
        get { recitationLanguage }
        set { guidanceLanguage = newValue; recitationLanguage = newValue }
    }

    var pace: PrayerPace {
        didSet { UserDefaults.standard.set(pace.rawValue, forKey: Keys.pace) }
    }

    var guidanceLevel: GuidanceLevel {
        didSet { UserDefaults.standard.set(guidanceLevel.rawValue, forKey: Keys.guidance) }
    }

    var salatType: SalatType {
        didSet { UserDefaults.standard.set(salatType.rawValue, forKey: Keys.salatType) }
    }

    /// IDs of toggled sunnah/witr units (farḍ is always included, never stored here)
    var selectedUnitIds: Set<String> {
        didSet {
            let arr = Array(selectedUnitIds)
            UserDefaults.standard.set(arr, forKey: Keys.unitIds)
        }
    }

    var muezzinId: String {
        didSet { UserDefaults.standard.set(muezzinId, forKey: Keys.muezzin) }
    }

    /// When on, the Muezzin's congregational frame (iqāma · boundary du'ā · dhikr seal)
    /// wraps each guided prayer. Default off — the frame is silent until Stage 3 voice
    /// binding, so it stays opt-in until then. See CONGREGATIONAL-CONTAINER.md §4.
    var muezzinEnabled: Bool {
        didSet { UserDefaults.standard.set(muezzinEnabled, forKey: Keys.muezzinEnabled) }
    }

    /// Spoken guidance voice timbre (Masculine/Feminine). Persisted; TTS binding TBD.
    var guidanceVoice: VoiceGender {
        didSet { UserDefaults.standard.set(guidanceVoice.rawValue, forKey: Keys.guidanceVoice) }
    }

    private init() {
        let defaults = UserDefaults.standard
        let legacyLang = defaults.string(forKey: Keys.language)   // migrate old single setting
        guidanceLanguage   = Language(rawValue: defaults.string(forKey: Keys.guidanceLanguage)   ?? legacyLang ?? "") ?? .english
        recitationLanguage = Language(rawValue: defaults.string(forKey: Keys.recitationLanguage) ?? legacyLang ?? "") ?? .english
        reciterId        = defaults.string(forKey: Keys.reciter) ?? RecitationVoices.defaultID
        pace             = PrayerPace(rawValue:    defaults.string(forKey: Keys.pace)      ?? "") ?? .medium
        guidanceLevel    = GuidanceLevel(rawValue: defaults.string(forKey: Keys.guidance)  ?? "") ?? .full
        salatType        = SalatType(rawValue:     defaults.string(forKey: Keys.salatType) ?? "") ?? .maghrib
        selectedUnitIds  = Set(defaults.stringArray(forKey: Keys.unitIds) ?? [])
        muezzinId        = defaults.string(forKey: Keys.muezzin) ?? Muezzins.defaultID
        muezzinEnabled   = defaults.object(forKey: Keys.muezzinEnabled) as? Bool ?? false
        guidanceVoice    = VoiceGender(rawValue: defaults.string(forKey: Keys.guidanceVoice) ?? "") ?? .masculine
    }

    private enum Keys {
        static let language  = "selectedPrayerLanguage"   // legacy — migration source only
        static let guidanceLanguage   = "selectedGuidanceLanguage"
        static let recitationLanguage = "selectedRecitationLanguage"
        static let reciter   = "selectedReciterId"
        static let pace      = "selectedPrayerPace"
        static let guidance  = "selectedGuidanceLevel"
        static let salatType = "selectedSalatType"
        static let unitIds   = "selectedUnitIds"
        static let muezzin   = "selectedMuezzinId"
        static let muezzinEnabled = "muezzinModeEnabled"
        static let guidanceVoice  = "selectedGuidanceVoice"
    }
}
