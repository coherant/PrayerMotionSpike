import SwiftUI

// Main menu — vertical card list (Mindfulness-style): full-width rounded cards, one per
// feature, with the watchOS carousel depth effect on scroll. Solid card colours are the
// iOS theme "top" colours (SalahMotion/DesignSystem/Tokens/PrayerTime.swift + DayTheme.swift).
struct MainMenuView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                card(title: "Prayer Times",  icon: "clock",                color: Theme.asr)     { PrayerTimesWatchView() }
                card(title: "Guided Prayer",  icon: "figure.mind.and.body", color: Theme.maghrib) { GuidedPrayerWatchView() }
                card(title: "Calibration",    icon: "scope",                color: Theme.fajr)    { CalibrationWatchView() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func card<D: View>(title: String, icon: String, color: Color,
                               @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color)
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
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

// The iOS theme "top" colours (deep sky of each prayer's hour).
enum Theme {
    static let fajr    = Color(hex: "#0d1430")   // deep midnight navy (dawn blue hour)
    static let dhuhr   = Color(hex: "#8fb8df")   // soft daytime sky blue
    static let asr     = Color(hex: "#14568f")   // deep saturated azure
    static let maghrib = Color(hex: "#241640")   // dark indigo-purple
    static let isha    = Color(hex: "#201b3a")   // dark violet
    static let dusk    = Color(hex: "#1a1836")   // deep indigo (dusk blue hour)
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
