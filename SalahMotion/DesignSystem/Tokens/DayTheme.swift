import SwiftUI
import UIKit

// MARK: - DayTheme — time-based atmospheric theme cross-fade
//
// The atmospheric theme cross-fades from one prayer period to the next over
// windows anchored to the ENGINE'S REAL times (Fajr / Sunrise / Asr / Maghrib),
// so it auto-adjusts by season and location. Spec: docs/design-reference/theme.md §9.
//
// Used by the prominent prayer-facing screens (Prayer Times; Guided uses the
// dominant period). Chrome screens (Settings, Calibration, Prayer Setup) do not.

// MARK: - SkyKeyframe
//
// One stop on the day's atmospheric timeline. Most are a prayer's own theme; the
// dusk blue hour is a standalone keyframe (Fajr's mirror on the dusk side). Each
// carries the prayer its labels/icons read as, and whether its background is the
// night radial + starfield. See theme.md §10.

struct SkyKeyframe: Equatable {
    let id: String
    let theme: PrayerTimeTheme
    let label: PrayerTime       // discrete labels/icons (.phase, .arabic, …)
    let night: Bool             // night radial + starfield, else linear gradient

    static func == (a: SkyKeyframe, b: SkyKeyframe) -> Bool { a.id == b.id }

    static func prayer(_ p: PrayerTime) -> SkyKeyframe {
        SkyKeyframe(id: p.rawValue, theme: p.theme, label: p, night: p == .isha)
    }

    /// Fajr's dusk mirror — the sunset→night blue hour. See theme.md §1.
    static let duskBlueHour = SkyKeyframe(
        id: "duskBlueHour", theme: .duskBlueHour, label: .maghrib, night: false
    )

    @ViewBuilder var background: some View {
        if night {
            ZStack {
                RadialGradient(
                    stops: theme.gradientStops,
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: 600
                )
                StarfieldView(count: 55)
            }
        } else {
            LinearGradient(stops: theme.gradientStops, startPoint: .top, endPoint: .bottom)
        }
    }
}

struct ThemeBlend {
    let from: SkyKeyframe
    let to: SkyKeyframe
    let t: Double            // 0 = from, 1 = to

    /// The period to use for discrete labels/icons (.phase, .arabic, …).
    var dominant: PrayerTime { (t < 0.5 ? from : to).label }

    /// Interpolated token colours (ink/muted/accent/glow/orb …).
    var theme: PrayerTimeTheme { PrayerTimeTheme.lerp(from.theme, to.theme, t) }

    /// Full-bleed background. A solid gradient when not transitioning; during a
    /// transition the `to` keyframe cross-fades in over the `from` keyframe
    /// (opacity stack — handles linear↔radial changes, e.g. dusk→Isha stars in).
    @ViewBuilder var background: some View {
        ZStack {
            from.background
            if from != to {
                to.background.opacity(t)
            }
        }
    }
}

enum DayTheme {

    /// The active blend for `now`, from real sun-altitude anchors (theme.md §10).
    /// Uses the PURE `twilightAnchors(for:)` / `computeTimes(for:)` so it works for
    /// ANY date with no side effects — which lets the time-machine egg rewind.
    // One-entry memo: `theme`/`accent`/`ink`/`background`/… are uncached computed
    // properties that each re-read `blend`, so a single view render fires dozens of
    // calls — all with the SAME `now`. Without this, the egg sweep recomputed Adhan
    // ~100×/frame (~800 ms/s) and stuttered. All reads in a render share one `now`,
    // so they collapse to one compute; the next render's `now` differs and refreshes.
    private static var cacheKey: Date?
    private static var cacheValue: ThemeBlend?

    static func blend(at now: Date = Date(), engine: PrayerTimesEngine = .shared) -> ThemeBlend {
        if cacheKey == now, let cached = cacheValue { return cached }
        let value = blendImpl(at: now, engine: engine)
        cacheKey = now
        cacheValue = value
        return value
    }

    private static func blendImpl(at now: Date, engine: PrayerTimesEngine) -> ThemeBlend {
        let night = ThemeBlend(from: .prayer(.isha), to: .prayer(.isha), t: 0)
        guard let a = engine.twilightAnchors(for: now),
              let asr = engine.computeTimes(for: now)?.times[.asr] else {
            return night   // pre-compute / polar fallback → solid Isha
        }

        // Keyframe timeline, chronological. Between two keyframes every token
        // interpolates; outside the day's first/last anchor it is solid Isha.
        // Sorted defensively in case an anchor crosses Asr at extreme latitude.
        let timeline: [(Date, SkyKeyframe)] = [
            (a.astronomicalDawn, .prayer(.isha)),     // night holds
            (a.nauticalDawn,     .prayer(.fajr)),     // Isha → Fajr: deep-blue first light
            (a.sunrise,          .prayer(.fajr)),     // Fajr holds: the dawn blue hour
            (a.morningGold,      .prayer(.dhuhr)),    // Fajr → Dhuhr: sunrise ignites the day
            (asr,                .prayer(.asr)),      // Dhuhr → Asr: the long afternoon warm
            (a.eveningGold,      .prayer(.asr)),      // Asr holds: the painted world
            (a.sunset,           .prayer(.maghrib)),  // Asr → Maghrib: golden hour into fire
            (a.civilDusk,        .duskBlueHour),      // Maghrib → dusk blue hour
            (a.nauticalDusk,     .duskBlueHour),      // the blue hour holds
            (a.astronomicalDusk, .prayer(.isha)),     // dusk blue hour → night
        ].sorted { $0.0 < $1.0 }

        guard let first = timeline.first, now > first.0 else { return night }
        for i in 1..<timeline.count {
            let (t0, k0) = timeline[i - 1]
            let (t1, k1) = timeline[i]
            if now <= t1 {
                let span = t1.timeIntervalSince(t0)
                let t = span > 0 ? now.timeIntervalSince(t0) / span : 1
                return ThemeBlend(from: k0, to: k1, t: min(max(t, 0), 1))
            }
        }
        return night   // after astronomical dusk → night
    }

    /// The dominant period right now (real-time-based).
    static var currentPeriod: PrayerTime { blend().dominant }
}

// MARK: - Dusk blue hour theme (transitional keyframe — see theme.md §1)

extension PrayerTimeTheme {
    static let duskBlueHour = PrayerTimeTheme(
        gradientStops: [
            .init(color: Color(hex: "#1a1836"), location: 0.00),
            .init(color: Color(hex: "#36325f"), location: 0.45),
            .init(color: Color(hex: "#6a4a6e"), location: 0.75),
            .init(color: Color(hex: "#9a5e63"), location: 1.00),
        ],
        isLight:  false,
        ink:      Color(hex: "#f4f1fa"),
        muted:    Color(hex: "#a39db6"),
        faint:    Color(hex: "#7d7790"),
        faintest: Color(hex: "#4f4a63"),
        accent:   Color(hex: "#cf9a86"),
        glow:     Color(hex: "#cf9a86").opacity(0.85),
        orbA:     Color(hex: "#e8d2dc"),
        orbB:     Color(hex: "#cf9a86"),
        orbInk:   Color(hex: "#16142a").opacity(0.60)
    )
}

// MARK: - Interpolation

extension PrayerTimeTheme {
    static func lerp(_ a: PrayerTimeTheme, _ b: PrayerTimeTheme, _ t: Double) -> PrayerTimeTheme {
        if t <= 0 { return a }
        if t >= 1 { return b }
        return PrayerTimeTheme(
            gradientStops: t < 0.5 ? a.gradientStops : b.gradientStops,  // bg is stacked, not lerped
            isLight:  t < 0.5 ? a.isLight : b.isLight,
            ink:      .lerp(a.ink, b.ink, t),
            muted:    .lerp(a.muted, b.muted, t),
            faint:    .lerp(a.faint, b.faint, t),
            faintest: .lerp(a.faintest, b.faintest, t),
            accent:   .lerp(a.accent, b.accent, t),
            glow:     .lerp(a.glow, b.glow, t),
            orbA:     .lerp(a.orbA, b.orbA, t),
            orbB:     .lerp(a.orbB, b.orbB, t),
            orbInk:   .lerp(a.orbInk, b.orbInk, t)
        )
    }
}

extension Color {
    /// Linear interpolation in sRGB (incl. alpha).
    static func lerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let u = CGFloat(min(max(t, 0), 1))
        let ca = UIColor(a).rgbaComponents, cb = UIColor(b).rgbaComponents
        return Color(.sRGB,
                     red:     Double(ca.r + (cb.r - ca.r) * u),
                     green:   Double(ca.g + (cb.g - ca.g) * u),
                     blue:    Double(ca.b + (cb.b - ca.b) * u),
                     opacity: Double(ca.a + (cb.a - ca.a) * u))
    }
}

private extension UIColor {
    var rgbaComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
