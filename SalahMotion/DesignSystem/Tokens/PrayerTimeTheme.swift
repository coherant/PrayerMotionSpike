import SwiftUI

enum PrayerTime: String, CaseIterable, Identifiable {
    case fajr, dhuhr, asr, maghrib, isha
    var id: String { rawValue }

    // Approximate fixed-time mapping — replace with adhan calculation when ready.
    // Fajr  04:00–05:59 · Dhuhr 06:00–14:59 · Asr 15:00–17:59
    // Maghrib 18:00–19:59 · Isha  20:00–03:59
    static var current: PrayerTime {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<6:   return .fajr
        case 6..<15:  return .dhuhr
        case 15..<18: return .asr
        case 18..<20: return .maghrib
        default:      return .isha
        }
    }

    var displayName: String {
        switch self {
        case .fajr:    return "Fajr"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    var theme: PrayerTimeTheme {
        switch self {
        case .fajr:
            return PrayerTimeTheme(
                gradientTop:    Color(red: 0.10, green: 0.08, blue: 0.21),
                gradientBottom: Color(red: 0.24, green: 0.13, blue: 0.26),
                orbGlow:        Color(red: 0.78, green: 0.50, blue: 0.56),
                accent:         Color(red: 0.78, green: 0.50, blue: 0.56),
                textPrimary:    Color(red: 0.12, green: 0.06, blue: 0.14)
            )
        case .dhuhr:
            return PrayerTimeTheme(
                gradientTop:    Color(red: 0.48, green: 0.56, blue: 0.68),
                gradientBottom: Color(red: 0.75, green: 0.66, blue: 0.51),
                orbGlow:        Color(red: 0.91, green: 0.84, blue: 0.66),
                accent:         Color(red: 0.91, green: 0.84, blue: 0.66),
                textPrimary:    Color(red: 0.20, green: 0.15, blue: 0.06)
            )
        case .asr:
            return PrayerTimeTheme(
                gradientTop:    Color(red: 0.66, green: 0.56, blue: 0.38),
                gradientBottom: Color(red: 0.54, green: 0.35, blue: 0.13),
                orbGlow:        Color(red: 0.88, green: 0.63, blue: 0.19),
                accent:         Color(red: 0.88, green: 0.63, blue: 0.19),
                textPrimary:    Color(red: 0.22, green: 0.14, blue: 0.04)
            )
        case .maghrib:
            return PrayerTimeTheme(
                gradientTop:    Color(red: 0.04, green: 0.03, blue: 0.06),
                gradientBottom: Color(red: 0.29, green: 0.11, blue: 0.03),
                orbGlow:        Color(red: 0.88, green: 0.35, blue: 0.16),
                accent:         Color(red: 0.88, green: 0.35, blue: 0.16),
                textPrimary:    Color(red: 0.16, green: 0.05, blue: 0.02)
            )
        case .isha:
            return PrayerTimeTheme(
                gradientTop:    Color(red: 0.03, green: 0.04, blue: 0.09),
                gradientBottom: Color(red: 0.10, green: 0.06, blue: 0.25),
                orbGlow:        Color(red: 0.60, green: 0.47, blue: 0.85),
                accent:         Color(red: 0.60, green: 0.47, blue: 0.85),
                textPrimary:    Color(red: 0.06, green: 0.04, blue: 0.14)
            )
        }
    }
}

struct PrayerTimeTheme {
    let gradientTop: Color
    let gradientBottom: Color
    let orbGlow: Color
    let accent: Color
    let textPrimary: Color
}
