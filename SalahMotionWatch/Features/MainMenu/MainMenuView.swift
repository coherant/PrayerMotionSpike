import SwiftUI

// Main menu — a simple vertical card list (the Mindfulness-app layout pattern: full-width
// rounded cards, Crown-scroll, tap to enter). One card per watch feature. Cards use the
// iPhone app's top gradient (Fajr dawn, for now — the app's gradient is prayer-time-based;
// per-prayer theming on the watch is a later arc).
struct MainMenuView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                card(title: "Prayer Times", icon: "clock") { PrayerTimesWatchView() }
                card(title: "Guided Prayer", icon: "figure.mind.and.body") { GuidedPrayerWatchView() }
                card(title: "Calibration", icon: "scope") { CalibrationWatchView() }
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
                    .fill(Self.cardGradient)
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
    }

    // The iPhone app's top gradient (SalahMotion/DesignSystem/Tokens/PrayerTime.swift — Fajr).
    private static let cardGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "#0d1430"), location: 0.00),
            .init(color: Color(hex: "#1c2147"), location: 0.36),
            .init(color: Color(hex: "#46324f"), location: 0.64),
            .init(color: Color(hex: "#8a5560"), location: 0.84),
            .init(color: Color(hex: "#d18d6c"), location: 1.00),
        ],
        startPoint: .top, endPoint: .bottom
    )
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
