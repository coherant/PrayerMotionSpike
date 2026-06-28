import SwiftUI

// MARK: - CelestialArcView
//
// The thin SwiftUI consumer of the Core/Celestial domain. It owns only timing
// (TimelineView) and measurement (GeometryReader); all astronomy/geometry comes
// from the platform-agnostic facade, so a watchOS view could differ here alone.
//
// It deliberately applies NO clip of its own — the Up Next card is the single
// clip authority (see docs/features/prayer-times/celestial-complications.md §3).
// All glow/shadow is composed here, INSIDE that clip, so nothing bleeds past the
// card edge.

struct CelestialArcView: View {
    let sky: CelestialSky
    var geometry = CelestialArcGeometry()
    /// The host's wall clock, ticked once a second by the screen. Drives the
    /// realtime branch so the ephemeris is evaluated in step with the countdown
    /// (rather than on a timeline of this view's own). Unused by demo/warp, which
    /// run their own frame-rate timelines.
    var now: Date
    /// Gate: tick only while the screen is foreground & active. Paused, the demo
    /// holds the last correct frame and snaps to `now` on resume (position is a
    /// pure function of time, so there is no state to restore).
    var isActive: Bool
    /// Seconds added to the wall clock (time-machine egg). 0 = real time.
    var timeOffset: TimeInterval = 0
    /// While the egg runs, animate at full frame rate regardless of cadence.
    var isWarping: Bool = false

    var body: some View {
        GeometryReader { proxy in
            if isWarping {
                // Time-machine rewind: full-rate so the sky sweeps smoothly.
                TimelineView(.animation) { timeline in
                    arc(in: proxy.size, at: timeline.date)
                }
            } else if sky.isDemo {
                // Demo: smooth animation, paused while the screen isn't active.
                TimelineView(.animation(paused: !isActive)) { timeline in
                    arc(in: proxy.size, at: timeline.date)
                }
            } else {
                // Realtime: ride the host's once-a-second tick instead of a private
                // timeline — one deterministic ephemeris (incl. SwiftAA) evaluation
                // per second, aligned with the countdown.
                arc(in: proxy.size, at: now)
            }
        }
    }

    private func arc(in size: CGSize, at date: Date) -> some View {
        let frame = sky.frame(atWallClock: date.addingTimeInterval(timeOffset))
        return ZStack {
            bodyView(.moon, state: frame.moon, in: size)
            bodyView(.sun, state: frame.sun, in: size)
        }
    }

    /// Positioning geometry with the arc-direction mirror applied for the
    /// observer's hemisphere (separate from the Moon's bright-limb mirror below).
    private var arcGeometry: CelestialArcGeometry {
        var g = geometry
        g.isNorthernHemisphere = sky.location.isNorthernHemisphere
        return g
    }

    @ViewBuilder
    private func bodyView(_ body: CelestialBody, state: SkyState, in size: CGSize) -> some View {
        let radius = arcGeometry.bodyRadius
        let point = arcGeometry.point(forDayPhase: state.dayPhase, in: size)
        Group {
            switch body {
            case .sun:
                Circle()
                    .fill(RadialGradient(
                        colors: [.white, Color(hex: "#FFD27A"), Color(hex: "#FFA82E")],
                        center: .center, startRadius: 0, endRadius: radius))
                    .shadow(color: Color(hex: "#FFB23E").opacity(0.85), radius: radius * 0.8)
            case .moon:
                MoonPhaseShape(phase: state.moonPhase?.phase ?? 0.5)
                    .fill(Color(hex: "#E8ECF2"))
                    // Southern-hemisphere mirror: the lit limb flips below the equator.
                    .scaleEffect(x: sky.location.isNorthernHemisphere ? 1 : -1)
                    .shadow(color: Color(hex: "#C9D4E6").opacity(0.5), radius: radius * 0.5)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .position(point)
        // Position is a pure function of (size, time) — it must SNAP, never tween.
        // Without this, an ambient transaction on first appear (the card's size
        // resolving, or the device coordinate replacing the Melbourne default and
        // flipping the hemisphere) catches `.position` and the disc slides in from
        // the horizon corner. nil-animation scoped to `point` overrides any such
        // inherited animation; demo/warp motion comes from per-frame recompute, not
        // implicit tweening, so smoothness is unaffected.
        .animation(nil, value: point)
    }
}
