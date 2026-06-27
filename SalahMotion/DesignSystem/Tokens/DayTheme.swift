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

struct ThemeBlend {
    let from: PrayerTime
    let to: PrayerTime
    let t: Double            // 0 = from, 1 = to

    /// The period to use for discrete labels/icons (.phase, .arabic, …).
    var dominant: PrayerTime { t < 0.5 ? from : to }

    /// Interpolated token colours (ink/muted/accent/glow/orb …).
    var theme: PrayerTimeTheme { PrayerTimeTheme.lerp(from.theme, to.theme, t) }

    /// Full-bleed background. A solid gradient when not transitioning; during a
    /// transition the `to` gradient cross-fades in over the `from` gradient
    /// (opacity stack — handles linear↔radial type changes, e.g. Maghrib→Isha).
    @ViewBuilder var background: some View {
        ZStack {
            from.backgroundGradient
            if from != to {
                to.backgroundGradient.opacity(t)
            }
        }
    }
}

enum DayTheme {

    /// The active blend for `now`, from the engine's real prayer/sunrise times.
    static func blend(at now: Date = Date(), engine: PrayerTimesEngine = .shared) -> ThemeBlend {
        engine.refreshIfNeeded(now: now)
        guard let fajr = engine.date(for: .fajr),
              let sunrise = engine.sunrise,
              let asr = engine.date(for: .asr),
              let maghrib = engine.date(for: .maghrib) else {
            return ThemeBlend(from: .isha, to: .isha, t: 0)   // pre-compute fallback
        }
        func shifted(_ d: Date, _ minutes: Double) -> Date { d.addingTimeInterval(minutes * 60) }

        // (start, end, from, to) — chronological. See theme.md §9.
        let windows: [(start: Date, end: Date, from: PrayerTime, to: PrayerTime)] = [
            (fajr,                shifted(fajr, 15),     .isha,    .fajr),
            (sunrise,             shifted(sunrise, 15),  .fajr,    .dhuhr),
            (shifted(asr, -30),   asr,                   .dhuhr,   .asr),
            (shifted(maghrib, -30), maghrib,             .asr,     .maghrib),
            (shifted(maghrib, 30),  shifted(maghrib, 60), .maghrib, .isha),
        ]

        var solid: PrayerTime = .isha   // before the first window it's still night
        for w in windows {
            if now < w.start { return ThemeBlend(from: solid, to: solid, t: 0) }
            if now <= w.end {
                let span = w.end.timeIntervalSince(w.start)
                let t = span > 0 ? now.timeIntervalSince(w.start) / span : 1
                return ThemeBlend(from: w.from, to: w.to, t: min(max(t, 0), 1))
            }
            solid = w.to
        }
        return ThemeBlend(from: solid, to: solid, t: 0)   // after last window → Isha
    }

    /// The dominant period right now (real-time-based). Replaces the old
    /// hardcoded clock-hour mapping.
    static var currentPeriod: PrayerTime { blend().dominant }
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
