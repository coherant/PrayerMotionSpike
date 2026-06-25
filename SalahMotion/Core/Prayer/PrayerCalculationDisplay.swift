import Foundation

// MARK: - UI display names for the Adhan calculation enums
//
// The vendored Adhan types are bare raw enums. These extensions provide the
// human-readable labels the Settings screen shows. Kept out of the vendored
// source so updating Adhan never clobbers them.

extension CalculationMethod {
    /// Methods offered in Settings — everything except `.other` (the custom placeholder).
    static var selectable: [CalculationMethod] {
        allCases.filter { $0 != .other }
    }

    var displayName: String {
        switch self {
        case .muslimWorldLeague:    return "Muslim World League"
        case .egyptian:             return "Egyptian General Authority"
        case .karachi:              return "Islamic University, Karachi"
        case .ummAlQura:            return "Umm al-Qura, Makkah"
        case .dubai:                return "Dubai (UAE)"
        case .moonsightingCommittee:return "Moonsighting Committee"
        case .northAmerica:         return "North America (ISNA)"
        case .kuwait:               return "Kuwait"
        case .qatar:                return "Qatar"
        case .singapore:            return "Singapore"
        case .tehran:               return "Tehran"
        case .turkey:               return "Turkey (Diyanet)"
        case .other:                return "Custom"
        }
    }
}

extension PrayerTime {
    /// Arabic name — exact spellings shared with `SalatType.arabicName`.
    var arabicName: String {
        switch self {
        case .fajr:    return "الفجر"
        case .dhuhr:   return "الظهر"
        case .asr:     return "العصر"
        case .maghrib: return "المغرب"
        case .isha:    return "العشاء"
        }
    }
}

extension Madhab {
    var displayName: String {
        switch self {
        case .shafi:  return "Standard"
        case .hanafi: return "Ḥanafī"
        }
    }

    /// Longer description shown as a subtitle.
    var detail: String {
        switch self {
        case .shafi:  return "Shāfiʿī, Mālikī, Ḥanbalī"
        case .hanafi: return "Later Asr shadow length"
        }
    }
}
