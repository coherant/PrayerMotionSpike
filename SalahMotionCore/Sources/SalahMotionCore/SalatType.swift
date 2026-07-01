import Foundation

// MARK: - Prayer unit (one selectable block within a session)
// Source: docs/features/prayer-setup/SPEC.md §4 & §5

public struct PrayerUnit: Identifiable {
    public enum Kind {
        case fard
        case sunnahBefore(emphasised: Bool)
        case sunnahAfter(emphasised: Bool)
        case witr
    }

    public let id: String
    public let kind: Kind
    public let rakats: Int

    public var isObligatory: Bool {
        if case .fard = kind { return true }
        return false
    }

    public var displayName: String {
        switch kind {
        case .fard:                       return "Farḍ"
        case .sunnahBefore, .sunnahAfter: return "Sunnah"
        case .witr:                       return "Witr"
        }
    }

    public var arabicName: String {
        switch kind {
        case .fard:                       return "فرض"
        case .sunnahBefore, .sunnahAfter: return "سنة"
        case .witr:                       return "وتر"
        }
    }

    public var tagText: String {
        switch kind {
        case .fard:
            return "Obligatory"
        case .sunnahBefore(let emph):
            return "Before farḍ · \(emph ? "emphasised" : "optional")"
        case .sunnahAfter(let emph):
            return "After farḍ · \(emph ? "emphasised" : "optional")"
        case .witr:
            return "After ʿIshāʾ · witr"
        }
    }
}

// MARK: - Salat type

public enum SalatType: String, CaseIterable, Identifiable {
    case fajr    = "fajr"
    case dhuhr   = "dhuhr"
    case asr     = "asr"
    case maghrib = "maghrib"
    case isha    = "isha"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fajr:    return "Fajr"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    // Exact spellings from SPEC.md §6
    public var arabicName: String {
        switch self {
        case .fajr:    return "الفجر"
        case .dhuhr:   return "الظهر"
        case .asr:     return "العصر"
        case .maghrib: return "المغرب"
        case .isha:    return "العشاء"
        }
    }

    public var periodLabel: String {
        switch self {
        case .fajr:    return "Before sunrise"
        case .dhuhr:   return "Midday"
        case .asr:     return "Afternoon"
        case .maghrib: return "Sunset"
        case .isha:    return "Night"
        }
    }

    // `prayerTime` (bridge to the PrayerTime enum) and `current(now:)` both live
    // app-side in SalatType+PrayerTimes.swift — they depend on the prayer-times /
    // adhan domain (PrayerTime, PrayerTimesEngine), which is not part of the
    // guided-engine core.

    // All units for this prayer in display order.
    // Farḍ is always first; sunnah before farḍ appears before it; witr last.
    public var units: [PrayerUnit] {
        switch self {
        case .fajr:
            return [
                PrayerUnit(id: "fajr_sb",  kind: .sunnahBefore(emphasised: true),  rakats: 2),
                PrayerUnit(id: "fajr_f",   kind: .fard,                             rakats: 2),
            ]
        case .dhuhr:
            return [
                PrayerUnit(id: "dhuhr_sb", kind: .sunnahBefore(emphasised: true),  rakats: 4),
                PrayerUnit(id: "dhuhr_f",  kind: .fard,                             rakats: 4),
                PrayerUnit(id: "dhuhr_sa", kind: .sunnahAfter(emphasised: true),   rakats: 2),
            ]
        case .asr:
            return [
                PrayerUnit(id: "asr_sb",   kind: .sunnahBefore(emphasised: false), rakats: 4),
                PrayerUnit(id: "asr_f",    kind: .fard,                             rakats: 4),
            ]
        case .maghrib:
            return [
                PrayerUnit(id: "maghrib_f",  kind: .fard,                           rakats: 3),
                PrayerUnit(id: "maghrib_sa", kind: .sunnahAfter(emphasised: true),  rakats: 2),
            ]
        case .isha:
            return [
                PrayerUnit(id: "isha_sb",   kind: .sunnahBefore(emphasised: false), rakats: 4),
                PrayerUnit(id: "isha_f",    kind: .fard,                            rakats: 4),
                PrayerUnit(id: "isha_sa",   kind: .sunnahAfter(emphasised: true),   rakats: 2),
                PrayerUnit(id: "isha_witr", kind: .witr,                            rakats: 3),
            ]
        }
    }

    public var fardRakats: Int { units.first(where: \.isObligatory)?.rakats ?? 0 }
}

// MARK: - Muezzin

public struct Muezzin: Identifiable {
    public let id: String
    public let latinName: String
    public let arabicName: String
    public let arabicInitial: String
    public let style: String
}

public enum Muezzins {
    public static let all: [Muezzin] = [
        Muezzin(id: "munadi-ai", latinName: "Munādī AI", arabicName: "منادي", arabicInitial: "م", style: "AI muezzin · clear, measured"),
        Muezzin(id: "bilal",  latinName: "Bilāl",  arabicName: "بلال",   arabicInitial: "ب", style: "Madinah cadence · unhurried"),
        Muezzin(id: "idris",  latinName: "Idrīs",  arabicName: "إدريس",  arabicInitial: "إ", style: "Flowing · melodic"),
        Muezzin(id: "sadiq",  latinName: "Ṣādiq",  arabicName: "صادق",   arabicInitial: "ص", style: "Spacious · minimal"),
        Muezzin(id: "yunus",  latinName: "Yūnus",  arabicName: "يونس",   arabicInitial: "ي", style: "Bright · resonant"),
    ]
    public static let defaultID = "munadi-ai"
}

// MARK: - RecitationVoice (Qāri') — voices the recitation (P)
// Temporary list; Muʿallim AI (the default) is the only one with recordings — others
// fall back to TTS until imported. Selection lives in UserPreferences.reciterId.

public struct RecitationVoice: Identifiable {
    public let id: String
    public let latinName: String
    public let arabicName: String
    public let style: String
}

public enum RecitationVoices {
    public static let all: [RecitationVoice] = [
        RecitationVoice(id: "muallim-ai", latinName: "Muʿallim AI", arabicName: "معلّم", style: "AI voice · clear, measured"),
        RecitationVoice(id: "ubayy", latinName: "Ubayy", arabicName: "أبيّ",  style: "Warm · deliberate"),
        RecitationVoice(id: "zayd",  latinName: "Zayd",  arabicName: "زيد",   style: "Bright · flowing"),
        RecitationVoice(id: "tamim", latinName: "Tamīm", arabicName: "تميم",  style: "Deep · resonant"),
    ]
    public static let defaultID = "muallim-ai"
}
