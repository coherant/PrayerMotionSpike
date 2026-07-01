import SwiftUI

// Main menu — vertical card list (Mindfulness-style): full-width rounded cards, one per
// feature, with the watchOS carousel depth effect on scroll. All cards share the day's
// ACTIVE theme (approximated by clock hour until prayer-times reach the watch), using the
// iOS theme's top + ink colours (SalahMotion/DesignSystem/Tokens/PrayerTime.swift).
struct MainMenuView: View {
    private let theme = DayThemes.active

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                card(title: "Prayer Times",  icon: "clock")                { PrayerTimesWatchView() }
                card(title: "Guided Prayer",  icon: "figure.mind.and.body") { GuidedPrayerWatchView() }
                card(title: "Calibration",    icon: "scope")                { CalibrationWatchView() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func card<D: View>(title: String, icon: String,
                               @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.top)
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(theme.ink)
                    Spacer(minLength: 8)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
            }
            .frame(height: 112)
        }
        .buttonStyle(.plain)
        // watchOS carousel depth: cards recede + fade as they scroll to the edges.
        .scrollTransition { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.86)
                .opacity(phase.isIdentity ? 1 : 0.45)
        }
    }
}

// The iOS prayer themes — top (deep sky of the hour) + ink (legible text on it).
struct DayTheme {
    let top: Color
    let ink: Color
}

enum DayThemes {
    static let fajr    = DayTheme(top: Color(hex: "#0d1430"), ink: Color(hex: "#f7eef0"))
    static let dhuhr   = DayTheme(top: Color(hex: "#8fb8df"), ink: Color(hex: "#22323f"))
    static let asr     = DayTheme(top: Color(hex: "#14568f"), ink: Color(hex: "#f7ede1"))
    static let maghrib = DayTheme(top: Color(hex: "#241640"), ink: Color(hex: "#fbeede"))
    static let isha    = DayTheme(top: Color(hex: "#201b3a"), ink: Color(hex: "#f4f1fa"))

    // Approximate the active theme by clock hour. Exact per-prayer selection needs
    // prayer-times on the watch (a later arc) — this is a stand-in until then.
    static var active: DayTheme {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<7:   return fajr
        case 7..<13:  return dhuhr
        case 13..<17: return asr
        case 17..<19: return maghrib
        default:      return isha
        }
    }
}

extension Color {
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt64(s, radix: 16) ?? 0
        self.init(.sRGB,
                  red:   Double((v >> 16) & 0xff) / 255,
                  green: Double((v >> 8)  & 0xff) / 255,
                  blue:  Double(v & 0xff)         / 255,
                  opacity: 1)
    }
}
