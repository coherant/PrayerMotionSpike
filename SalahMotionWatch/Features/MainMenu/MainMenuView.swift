import SwiftUI

// Main menu — vertical card list (Mindfulness-style): full-width rounded cards, one per
// feature, with the watchOS carousel depth effect on scroll. All cards share the day's
// ACTIVE theme (approximated by clock hour until prayer-times reach the watch), using the
// iOS theme's top + ink colours (SalahMotion/DesignSystem/Tokens/PrayerTime.swift).
struct MainMenuView: View {
    private let theme = DayThemes.active
    private let location = WatchLocationManager.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                card(title: "Prayer Times",  icon: { symbol("clock") },
                     accessory: { locationCapsule }) { PrayerTimesWatchView() }
                card(title: "Guided Prayer",  icon: { PrayerBeadsIcon(color: theme.ink).frame(width: 26, height: 26) },
                     accessory: { EmptyView() }) { GuidedPrayerWatchView() }
                card(title: "Calibration",    icon: { symbol("scope") },
                     accessory: { EmptyView() }) { CalibrationWatchView() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .task { location.requestLocation() }
    }

    // Current location, matching the iPhone's location pill (mappin + city name).
    private var locationCapsule: some View {
        HStack(spacing: 3) {
            Image(systemName: "mappin.and.ellipse").font(.system(size: 8))
            Text(location.cityName).font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(theme.ink.opacity(0.9))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(theme.ink.opacity(0.15)))
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(theme.ink)
    }

    private func card<Icon: View, Accessory: View, D: View>(
        title: String,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder destination: @escaping () -> D
    ) -> some View {
        NavigationLink(destination: destination) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.top)
                VStack(alignment: .leading, spacing: 0) {
                    icon()
                        .frame(height: 26, alignment: .leading)
                    Spacer(minLength: 8)
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
            }
            .frame(height: 112)
            .overlay(alignment: .topTrailing) { accessory().padding(11) }
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

// Islamic prayer beads (misbaḥa / tasbīḥ): a loop of beads with the leader bead + tassel.
// Drawn as a vector since there's no SF Symbol for it.
struct PrayerBeadsIcon: View {
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w * 0.5
            let ringCY = h * 0.34
            let rx = w * 0.30, ry = h * 0.26
            let beadR = w * 0.058
            let count = 13

            // The loop of beads.
            for i in 0..<count {
                let a = Double(i) / Double(count) * 2 * .pi + .pi / 2   // start at the bottom
                let x = cx + rx * CGFloat(cos(a))
                let y = ringCY + ry * CGFloat(sin(a))
                ctx.fill(Path(ellipseIn: CGRect(x: x - beadR, y: y - beadR,
                                                width: beadR * 2, height: beadR * 2)),
                         with: .color(color))
            }

            // Leader bead (imāme) below the loop.
            let imR = beadR * 1.3
            let imCY = ringCY + ry + imR * 1.3
            ctx.fill(Path(ellipseIn: CGRect(x: cx - imR, y: imCY - imR,
                                            width: imR * 2, height: imR * 2)),
                     with: .color(color))

            // Tassel threads.
            var tassel = Path()
            let ty0 = imCY + imR * 0.7
            let tLen = h * 0.17
            for dx in [-imR * 0.55, 0, imR * 0.55] {
                tassel.move(to: CGPoint(x: cx + dx, y: ty0))
                tassel.addLine(to: CGPoint(x: cx + dx * 1.5, y: ty0 + tLen))
            }
            ctx.stroke(tassel, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1, w * 0.03), lineCap: .round))
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
