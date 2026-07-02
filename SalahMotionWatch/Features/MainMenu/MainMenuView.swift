import SwiftUI

// Main menu — vertical card list (Mindfulness-style): full-width rounded cards, one per
// feature, with the watchOS carousel depth effect on scroll. All cards share the day's
// active theme — the REAL current prayer from the on-wrist engine — using the iOS theme's
// top + ink colours (SalahMotion/DesignSystem/Tokens/PrayerTime.swift).
struct MainMenuView: View {
    private let location = WatchLocationManager.shared
    private let engine = WatchPrayerTimes.shared

    // The active theme = the REAL current prayer (from the on-wrist engine), re-evaluated on
    // the 60s tick in `body` so the card background + ink flip exactly at each prayer boundary,
    // in step with the rail. Falls back to the clock-hour approximation before times are computed.
    private var theme: DayTheme {
        let ordered = engine.ordered
        let idx = engine.currentPrayerIndex(at: Date())
        return ordered.indices.contains(idx) ? DayThemes.theme(for: ordered[idx].prayer) : DayThemes.active
    }

    var body: some View {
        // 60s tick: re-render the menu each minute so `theme` re-reads the current prayer and
        // the card background + ink update live at prayer boundaries (in step with the rail).
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            menu
        }
        .task { location.requestLocation() }
        .onAppear { engine.refreshIfNeeded() }
    }

    private var menu: some View {
        ScrollView {
            LazyVStack(spacing: 5) {
                // Prayer Times: no icon — the live Sun/Moon arc (mirroring the iPhone "Up
                // next" card) fills the card, with the day-progress rail at its foot. Both
                // ride one 60s tick — the real bodies move imperceptibly per minute, so a
                // coarse cadence is smooth and battery-cheap.
                card(title: "Prayer Times",  icon: { EmptyView() },
                     accessory: { locationCapsule },
                     background: {
                         TimelineView(.periodic(from: .now, by: 60)) { context in
                             CelestialArcView(sky: celestialSky,
                                              geometry: CelestialArcGeometry(topGap: 14, bodyRadius: 9),
                                              now: context.date,
                                              isActive: true)
                         }
                     },
                     footer: {
                         TimelineView(.periodic(from: .now, by: 60)) { context in
                             dayRail(now: context.date).padding(.bottom, 6)
                         }
                     }) { PrayerTimesWatchView() }
                card(title: "Guided Prayer",  icon: { PrayerBeadsIcon(color: theme.ink).frame(width: 26, height: 26) },
                     accessory: { EmptyView() }, background: { EmptyView() }, footer: { EmptyView() }) { GuidedPrayerWatchView() }
                card(title: "Calibration",    icon: { symbol("scope") },
                     accessory: { EmptyView() }, background: { EmptyView() }, footer: { EmptyView() }) { CalibrationWatchView() }
                card(title: "Settings",       icon: { symbol("gearshape") },
                     accessory: { EmptyView() }, background: { EmptyView() }, footer: { EmptyView() }) { WatchSettingsView() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    // The real Sun + Moon at the wrist's location — the same `.live` facade the iPhone
    // Up Next card binds to (Sun via Adhan, Moon via SwiftAA).
    private var celestialSky: CelestialSky {
        let c = engine.coordinate
        return .live(location: ObserverLocation(latitude: c.latitude,
                                                longitude: c.longitude,
                                                timeZone: engine.timeZone))
    }

    // MARK: - Day progress rail (Prayer Times card)
    //
    // Ports the iPhone rail (SalahMotion/Features/PrayerTimes/PrayerTimesView.swift `dayRail`),
    // scaled for the card: track + accent fill + five prayer nodes (solid = prayed, hollow ring
    // = current/future) + a pulse marker at the fill's leading edge. All state comes from the
    // already-ported WatchPrayerTimes rail helpers — no new logic here. Coloured by the card's
    // active theme so it reads as one with the card.
    private func dayRail(now: Date) -> some View {
        let currentIndex = engine.currentPrayerIndex(at: now)
        let fill = engine.continuousRailFill(at: now)
        // Colour the rail by the REAL current prayer (per-prayer accent table), not the
        // card's clock-hour theme — so the accent is exact at every prayer boundary.
        let ordered = engine.ordered
        let railTheme = ordered.indices.contains(currentIndex)
            ? DayThemes.theme(for: ordered[currentIndex].prayer)
            : theme
        let accent = railTheme.accent

        return GeometryReader { geo in
            let w = geo.size.width
            let track: Color = railTheme.isLight ? Color(hex: "#2b3a4a").opacity(0.12) : Color.white.opacity(0.14)
            let neutralRing: Color = railTheme.isLight ? Color(hex: "#2b3a4a").opacity(0.28) : Color.white.opacity(0.35)

            ZStack(alignment: .topLeading) {
                // Track
                Rectangle()
                    .fill(track)
                    .frame(width: w, height: 1.5)
                    .offset(y: 9)

                // Fill
                Rectangle()
                    .fill(accent)
                    .frame(width: w * fill, height: 1.5)
                    .offset(y: 9)

                // Prayer nodes
                ForEach(Array(WatchPrayerTimes.railNodeFractions.enumerated()), id: \.offset) { i, pos in
                    if i < currentIndex {
                        // Prayed — filled solid dot
                        Circle()
                            .fill(accent)
                            .frame(width: 8, height: 8)
                            .offset(x: w * pos - 4, y: 5.5)
                    } else {
                        // Current or future — hollow ring
                        Circle()
                            .strokeBorder(neutralRing, lineWidth: 1.5)
                            .frame(width: 7, height: 7)
                            .offset(x: w * pos - 3.5, y: 6)
                    }
                }

                // Active pulse marker — sits at the end of the fill line
                PulseMarker(accent: accent)
                    .frame(width: 20, height: 20)
                    .offset(x: w * fill - 10, y: -1)
            }
        }
        .frame(height: 20)
    }

    // Current location, matching the iPhone's location pill (mappin + city name).
    private var locationCapsule: some View {
        HStack(spacing: 3) {
            Image(systemName: "mappin.and.ellipse").font(.system(size: 8))
            Text(location.cityName).font(Typography.ui(9, weight: .medium))
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

    private func card<Icon: View, Accessory: View, Background: View, Footer: View, D: View>(
        title: String,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder background: () -> Background,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder destination: @escaping () -> D
    ) -> some View {
        NavigationLink(destination: destination) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.top)
                // Celestial object (Sun/Moon arc) behind the UI, clipped to the card silhouette.
                background()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                VStack(alignment: .leading, spacing: 0) {
                    icon()
                        .frame(height: 26, alignment: .leading)
                    Spacer(minLength: 8)
                    footer()   // full-width, above the title (Prayer Times day rail)
                    Text(title)
                        .font(Typography.display(18, weight: .semibold))
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

// The iOS prayer themes — top (deep sky of the hour) + ink (legible text on it) +
// accent (the day-rail fill/nodes/pulse) + isLight (Dhuhr's near-white sky, which
// flips the rail's neutral track/ring shades). See SalahMotion/DesignSystem/Tokens/PrayerTime.swift.
struct DayTheme {
    let top: Color
    let ink: Color
    let accent: Color
    let isLight: Bool
}

enum DayThemes {
    // Rail `accent` values are the Complication Spec's day-cycle gauge gradient
    // (docs/features/watch/SalahMotion Complication Spec.md §Gauge Full Color Gradient):
    // Isha #4848a8 · Fajr #6878c0 · Dhuhr #8fb8df · Asr #c89030 · Maghrib #e09830.
    // `top`/`ink` remain the iOS sky theme — only the rail is spec-driven.
    static let fajr    = DayTheme(top: Color(hex: "#0d1430"), ink: Color(hex: "#f7eef0"), accent: Color(hex: "#6878c0"), isLight: false)
    static let dhuhr   = DayTheme(top: Color(hex: "#8fb8df"), ink: Color(hex: "#22323f"), accent: Color(hex: "#8fb8df"), isLight: true)
    static let asr     = DayTheme(top: Color(hex: "#14568f"), ink: Color(hex: "#f7ede1"), accent: Color(hex: "#c89030"), isLight: false)
    static let maghrib = DayTheme(top: Color(hex: "#241640"), ink: Color(hex: "#fbeede"), accent: Color(hex: "#e09830"), isLight: false)
    static let isha    = DayTheme(top: Color(hex: "#201b3a"), ink: Color(hex: "#f4f1fa"), accent: Color(hex: "#4848a8"), isLight: false)

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

    // The theme for a specific prayer — lets the day rail colour itself by the REAL
    // current prayer (from the on-wrist engine), not the clock-hour `active` stand-in.
    static func theme(for prayer: Prayer) -> DayTheme {
        switch prayer {
        case .fajr:    return fajr
        case .dhuhr:   return dhuhr
        case .asr:     return asr
        case .maghrib: return maghrib
        case .isha:    return isha
        case .sunrise: return dhuhr   // not an obligatory prayer; never a rail node
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

// Pulsing marker at the day rail's leading edge — a solid dot with a glow and an outward
// ripple. Self-contained (accent-driven), ported from the iPhone rail.
private struct PulseMarker: View {
    let accent: Color
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(accent, lineWidth: 1)
                .scaleEffect(pulsing ? 1.5 : 0.85)
                .opacity(pulsing ? 0 : 0.55)
                .animation(
                    .easeOut(duration: 3.6).repeatForever(autoreverses: false),
                    value: pulsing
                )
            Circle()
                .fill(accent)
                .frame(width: 11, height: 11)
                .shadow(color: accent.opacity(0.9), radius: 6)
        }
        .onAppear { pulsing = true }
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

// MARK: - Preview

// Hosted in a NavigationStack to match SalahMotionWatchApp, so the cards' NavigationLinks
// and the carousel scroll behaviour render as they do at runtime.
#Preview("Main Menu") {
    NavigationStack {
        MainMenuView()
    }
}
