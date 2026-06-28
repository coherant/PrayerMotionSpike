import SwiftUI
import simd

// MARK: - SkyBirdsView
//
// A reusable, view-only ambient layer: birds cross the sky using a 2.5D Boids
// flock (Reynolds 1987 — separation / alignment / cohesion + wander), so motion
// is EMERGENT, not scripted. Spec: docs/features/prayer-times/ambient-sky-birds.md.
//
//  • 2.5D — each bird carries a depth `z` (0…depthScale, in points); z → size +
//    opacity + apparent speed, giving continuous parallax (no flat layers).
//  • One engine, many "events": a lone wanderer is a 1-bird flock; a small group
//    or a 150-bird murmuration are the same rules with more members + a tighter
//    pull. Ambient events migrate across and are culled; the murmuration is
//    contained in a volume a little larger than the screen and swirls around a
//    slowly-wandering attractor (the "roost") until it disperses.
//  • Stateful simulation (unlike the celestial `f(now)`): the flock is stepped by
//    real dt each frame from a `TimelineView(.animation(paused:))`. Off-tab it
//    freezes; on return dt is clamped so nothing explodes.

// MARK: Tunables

enum BirdSkyConfig {
    /// Master feature flag — `false` short-circuits to nothing (no sim, no cost).
    static let isEnabled = true

    /// Virtual depth of the sky, in points. A bird's `z` runs 0 (far) … this (near).
    static let depthScale: Double = 240

    // Ambient density ("a regular day"): mostly loners, the odd small group.
    static let maxAmbientFlocks = 3
    static let ambientSpawnGap: ClosedRange<Double> = 9...22   // seconds between events
    /// Below this daylight factor ambient birds stop spawning (sky empties at night).
    static let daylightFloor: Double = 0.06

    /// The murmuration (egg stage 2).
    static let murmurationCount = 280
    /// Sim bounds extend this fraction beyond the screen on every side, so the
    /// swarm visibly drifts off-screen and back.
    static let simMargin: CGFloat = 0.22
}

// MARK: - Vector helpers

private func safeNormalize(_ v: SIMD3<Double>) -> SIMD3<Double> {
    let m = simd_length(v)
    return m > 1e-9 ? v / m : .zero
}

private func limit(_ v: SIMD3<Double>, _ maxLen: Double) -> SIMD3<Double> {
    let m = simd_length(v)
    return m > maxLen ? v / m * maxLen : v
}

private func clampSpeed(_ v: SIMD3<Double>, _ minSpeed: Double, _ maxSpeed: Double) -> SIMD3<Double> {
    let m = simd_length(v)
    if m > maxSpeed { return v / m * maxSpeed }
    if m < minSpeed && m > 1e-6 { return v / m * minSpeed }
    return v
}

private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
    a + (b - a) * CGFloat(min(max(t, 0), 1))
}

// MARK: - Boid & flock configuration

private struct Boid {
    var pos: SIMD3<Double>     // x,y in points (screen space); z in 0…depthScale
    var vel: SIMD3<Double>     // x,y pt/s; z depth pt/s
    var wander: Double         // wander heading (rad)
    var flapPhase: Double
    var flapRate: Double       // base wingbeats/sec
}

private enum Behavior {
    case migrate(SIMD3<Double>)   // steer along a unit direction; cull off-screen
    case contain                  // stay in bounds + seek the attractor
}

private struct FlockConfig {
    var maxSpeed: Double
    var minSpeed: Double
    var maxForce: Double
    var neighborRadius: Double
    var separationRadius: Double
    /// Topological flocking: when set, a bird orients/coheres to its K NEAREST
    /// neighbours regardless of distance (Ballerini et al. 2008, measured from real
    /// starling murmurations) instead of everyone within `neighborRadius`. This is
    /// what keeps a murmuration cohesive as density changes. nil = metric (ambient).
    var topologicalK: Int? = nil
    var wSeparation: Double
    var wAlignment: Double
    var wCohesion: Double
    var wWander: Double
    var wGoal: Double
    var wanderJitter: Double
    var boundaryMargin: Double
    var boundaryStrength: Double
    var behavior: Behavior
    var spanRange: ClosedRange<CGFloat>   // wingspan by depth (far…near)
    var baseOpacity: Double
    var respectsDaylight: Bool
}

private final class FlockGroup {
    var boids: [Boid]
    var config: FlockConfig
    var attractor: SIMD3<Double>
    var attractorVel: SIMD3<Double> = .zero
    var dispersing = false
    let isMurmuration: Bool

    init(boids: [Boid], config: FlockConfig, attractor: SIMD3<Double>, isMurmuration: Bool) {
        self.boids = boids
        self.config = config
        self.attractor = attractor
        self.isMurmuration = isMurmuration
    }
}

// MARK: - Flock engine (stepped each frame)

private final class Flock {
    var groups: [FlockGroup] = []

    private var lastDate: Date?
    private var nextSpawn: Date = .distantPast
    private var lastMurmuration = false

    /// Advance the whole simulation to `date`. Called once per frame from the view.
    func advance(to date: Date, size: CGSize, daylight: Double, murmuration: Bool) {
        guard size.width > 0 else { return }
        let bounds = simBounds(size)

        // dt clamped so an off-tab gap (or first frame) can't blow up the integrator.
        let dt = min(max(lastDate.map { date.timeIntervalSince($0) } ?? 0, 0), 1.0 / 20.0)
        lastDate = date

        // Murmuration edges (egg stage 2).
        if murmuration && !lastMurmuration { spawnMurmuration(in: bounds) }
        if !murmuration && lastMurmuration { disperseMurmurations() }
        lastMurmuration = murmuration

        scheduleAmbient(at: date, bounds: bounds, daylight: daylight)

        guard dt > 0 else { return }
        for group in groups { step(group, dt: dt, bounds: bounds) }
        groups.removeAll { $0.boids.isEmpty }
    }

    /// Snapshot for rendering (read by the Canvas).
    var renderGroups: [FlockGroup] { groups }

    // MARK: Bounds

    private func simBounds(_ size: CGSize) -> CGRect {
        let mx = size.width * BirdSkyConfig.simMargin
        let my = size.height * BirdSkyConfig.simMargin
        return CGRect(x: -mx, y: -my, width: size.width + 2 * mx, height: size.height + 2 * my)
    }

    // MARK: Stepping

    private func step(_ group: FlockGroup, dt: Double, bounds: CGRect) {
        let cfg = group.config

        // Wander the murmuration's roost so the swarm folds and ripples.
        if case .contain = cfg.behavior, !group.dispersing {
            group.attractorVel += randomUnit() * 40 * dt
            group.attractorVel = limit(group.attractorVel, 70)
            group.attractor += group.attractorVel * dt
            keepAttractorInside(group, bounds: bounds)
        }

        let snapshot = group.boids
        // Scratch for topological mode (K nearest), allocated once per group/frame
        // and refilled per bird — no per-bird allocation.
        let topoK = cfg.topologicalK ?? 0
        var nearDist = [Double](repeating: .infinity, count: topoK)
        var nearIdx = [Int](repeating: -1, count: topoK)

        for i in group.boids.indices {
            let b = snapshot[i]

            var avgVel = SIMD3<Double>.zero
            var avgPos = SIMD3<Double>.zero
            var separation = SIMD3<Double>.zero
            var n = 0

            if topoK > 0 {
                // Topological: keep the K nearest via insertion into a sorted buffer.
                for s in 0..<topoK { nearDist[s] = .infinity; nearIdx[s] = -1 }
                for j in snapshot.indices where j != i {
                    let dist = simd_length(snapshot[j].pos - b.pos)
                    guard dist > 1e-6, dist < nearDist[topoK - 1] else { continue }
                    var s = topoK - 1
                    while s > 0 && nearDist[s - 1] > dist {
                        nearDist[s] = nearDist[s - 1]; nearIdx[s] = nearIdx[s - 1]; s -= 1
                    }
                    nearDist[s] = dist; nearIdx[s] = j
                }
                for s in 0..<topoK where nearIdx[s] >= 0 {
                    let j = nearIdx[s]
                    avgVel += snapshot[j].vel
                    avgPos += snapshot[j].pos
                    n += 1
                    if nearDist[s] < cfg.separationRadius {
                        separation -= (snapshot[j].pos - b.pos) / nearDist[s]
                    }
                }
            } else {
                // Metric: everyone within `neighborRadius` (ambient birds).
                for j in snapshot.indices where j != i {
                    let off = snapshot[j].pos - b.pos
                    let dist = simd_length(off)
                    guard dist < cfg.neighborRadius, dist > 1e-6 else { continue }
                    avgVel += snapshot[j].vel
                    avgPos += snapshot[j].pos
                    n += 1
                    if dist < cfg.separationRadius { separation -= off / dist }
                }
            }

            var accel = SIMD3<Double>.zero
            if n > 0 {
                let inv = 1.0 / Double(n)
                accel += cfg.wAlignment * steer(avgVel * inv, b.vel, cfg)
                accel += cfg.wCohesion * steer(avgPos * inv - b.pos, b.vel, cfg)
            }
            accel += cfg.wSeparation * steer(separation, b.vel, cfg)

            // Wander — an aperiodic meander (this replaces the old scripted sine bob).
            let wander = b.wander + Double.random(in: -1...1) * cfg.wanderJitter * dt
            let wdir = SIMD3<Double>(cos(wander), sin(wander), Double.random(in: -0.25...0.25))
            accel += cfg.wWander * steer(wdir, b.vel, cfg)

            switch cfg.behavior {
            case .migrate(let dir):
                accel += cfg.wGoal * steer(dir, b.vel, cfg)
            case .contain:
                accel += cfg.wGoal * steer(group.attractor - b.pos, b.vel, cfg)
                accel += boundaryForce(b.pos, bounds: bounds, cfg: cfg)
            }

            accel = limit(accel, cfg.maxForce)
            var v = clampSpeed(b.vel + accel * dt, cfg.minSpeed, cfg.maxSpeed)
            var p = b.pos + v * dt

            // Bounce gently off the depth planes so birds stay in the slab.
            if p.z < 0 { p.z = 0; v.z = abs(v.z) * 0.5 }
            if p.z > BirdSkyConfig.depthScale { p.z = BirdSkyConfig.depthScale; v.z = -abs(v.z) * 0.5 }

            // Wings beat faster while climbing (moving up = −y), glide on the way down.
            let climb = max(0, -v.y) / cfg.maxSpeed
            group.boids[i].pos = p
            group.boids[i].vel = v
            group.boids[i].wander = wander
            group.boids[i].flapPhase += 2 * .pi * b.flapRate * (1 + 1.4 * climb) * dt
        }

        cull(group, bounds: bounds)
    }

    private func steer(_ desiredDir: SIMD3<Double>, _ vel: SIMD3<Double>, _ cfg: FlockConfig) -> SIMD3<Double> {
        let d = safeNormalize(desiredDir)
        guard d != .zero else { return .zero }
        return limit(d * cfg.maxSpeed - vel, cfg.maxForce)
    }

    private func boundaryForce(_ p: SIMD3<Double>, bounds: CGRect, cfg: FlockConfig) -> SIMD3<Double> {
        var f = SIMD3<Double>.zero
        let m = cfg.boundaryMargin
        if p.x < Double(bounds.minX) + m { f.x += (Double(bounds.minX) + m - p.x) }
        if p.x > Double(bounds.maxX) - m { f.x -= (p.x - (Double(bounds.maxX) - m)) }
        if p.y < Double(bounds.minY) + m { f.y += (Double(bounds.minY) + m - p.y) }
        if p.y > Double(bounds.maxY) - m { f.y -= (p.y - (Double(bounds.maxY) - m)) }
        return f * cfg.boundaryStrength
    }

    private func keepAttractorInside(_ group: FlockGroup, bounds: CGRect) {
        // Hold the roost within the central 70% so the swarm dances on-screen.
        let insetX = Double(bounds.width) * 0.15
        let insetY = Double(bounds.height) * 0.15
        if group.attractor.x < Double(bounds.minX) + insetX { group.attractorVel.x = abs(group.attractorVel.x) }
        if group.attractor.x > Double(bounds.maxX) - insetX { group.attractorVel.x = -abs(group.attractorVel.x) }
        if group.attractor.y < Double(bounds.minY) + insetY { group.attractorVel.y = abs(group.attractorVel.y) }
        if group.attractor.y > Double(bounds.maxY) - insetY { group.attractorVel.y = -abs(group.attractorVel.y) }
    }

    private func cull(_ group: FlockGroup, bounds: CGRect) {
        // Contained, still-dancing murmurations keep every member.
        if case .contain = group.config.behavior, !group.dispersing { return }
        let slack = 80.0
        group.boids.removeAll { b in
            b.pos.x < Double(bounds.minX) - slack || b.pos.x > Double(bounds.maxX) + slack ||
            b.pos.y < Double(bounds.minY) - slack || b.pos.y > Double(bounds.maxY) + slack
        }
    }

    // MARK: Ambient scheduling

    private func scheduleAmbient(at date: Date, bounds: CGRect, daylight: Double) {
        guard date >= nextSpawn else { return }
        nextSpawn = date.addingTimeInterval(Double.random(in: BirdSkyConfig.ambientSpawnGap))

        guard daylight >= BirdSkyConfig.daylightFloor else { return }
        let ambientCount = groups.filter { !$0.isMurmuration }.count
        guard ambientCount < BirdSkyConfig.maxAmbientFlocks else { return }

        // Mostly loners, sometimes a pair/trio, rarely a small flock.
        let roll = Double.random(in: 0...1)
        let count = roll < 0.6 ? 1 : (roll < 0.9 ? Int.random(in: 2...3) : Int.random(in: 6...11))
        groups.append(makeAmbient(count: count, bounds: bounds))
    }

    private func makeAmbient(count: Int, bounds: CGRect) -> FlockGroup {
        let leftToRight = Bool.random()
        let dir = SIMD3<Double>(leftToRight ? 1 : -1, Double.random(in: -0.15...0.15), 0)
        let speed = Double.random(in: 16...30)

        // Enter just off the leading edge, spread vertically over the sky band.
        let entryX = leftToRight ? Double(bounds.minX) - 20 : Double(bounds.maxX) + 20
        let bandTop = Double(bounds.minY) + Double(bounds.height) * 0.06
        let bandBottom = Double(bounds.minY) + Double(bounds.height) * 0.5
        let anchorY = Double.random(in: bandTop...bandBottom)

        let solo = count == 1
        let config = FlockConfig(
            maxSpeed: speed, minSpeed: speed * 0.55, maxForce: 26,
            neighborRadius: 70, separationRadius: 26,
            wSeparation: 1.6, wAlignment: solo ? 0 : 0.9, wCohesion: solo ? 0 : 0.7,
            wWander: solo ? 1.1 : 0.6, wGoal: 0.8,
            wanderJitter: solo ? 3.0 : 2.0,
            boundaryMargin: 0, boundaryStrength: 0,
            behavior: .migrate(safeNormalize(dir)),
            spanRange: 6...13, baseOpacity: 0.16, respectsDaylight: true)

        let boids: [Boid] = (0..<count).map { _ in
            Boid(pos: SIMD3(entryX + Double.random(in: -30...30),
                            anchorY + Double.random(in: -40...40),
                            Double.random(in: 0...BirdSkyConfig.depthScale)),
                 vel: safeNormalize(dir) * speed,
                 wander: Double.random(in: 0...(2 * .pi)),
                 flapPhase: Double.random(in: 0...(2 * .pi)),
                 flapRate: Double.random(in: 2.2...3.4))
        }
        return FlockGroup(boids: boids, config: config, attractor: .zero, isMurmuration: false)
    }

    // MARK: Murmuration (egg stage 2)

    private func spawnMurmuration(in bounds: CGRect) {
        // Flood in from a random edge toward the centre; the roost pulls them in.
        let center = SIMD3<Double>(Double(bounds.midX), Double(bounds.midY), BirdSkyConfig.depthScale / 2)
        let fromLeft = Bool.random()
        let entryX = fromLeft ? Double(bounds.minX) - 40 : Double(bounds.maxX) + 40
        let inward = safeNormalize(center - SIMD3(entryX, center.y, center.z))

        // Research-tuned. Steering model = Reynolds/Shiffman (desired−velocity,
        // capped at maxForce). Ratios from Cornell's Hunter Adams: minspeed = ½
        // maxspeed, protected:visual ≈ 1:5. Neighbours = ~7 nearest (Ballerini,
        // measured from real starlings). Weights are Shiffman's faithful ratio
        // (separation 1.5 / alignment 1.0 / cohesion 1.0); near-zero wander.
        let config = FlockConfig(
            maxSpeed: 143, minSpeed: 72, maxForce: 175,   // 1.5× fast; minspeed = ½ max (Cornell 1:2)
            neighborRadius: 64, separationRadius: 12,     // protected:visual ≈ 1:5 (Cornell)
            topologicalK: 7,                              // ~7 nearest (Ballerini, real starlings)
            wSeparation: 1.5, wAlignment: 1.0, wCohesion: 1.0,   // Shiffman's faithful weighting
            wWander: 0.1, wGoal: 0.7,
            wanderJitter: 0.4,                            // minimal heading noise (base flocking uses none)
            boundaryMargin: 70, boundaryStrength: 1.4,
            behavior: .contain,
            spanRange: 4...12, baseOpacity: 0.5, respectsDaylight: false)

        let boids: [Boid] = (0..<BirdSkyConfig.murmurationCount).map { _ in
            Boid(pos: SIMD3(entryX + Double.random(in: -120...120),
                            center.y + Double.random(in: -160...160),
                            Double.random(in: 0...BirdSkyConfig.depthScale)),
                 vel: inward * Double.random(in: 60...95) + randomUnit() * 20,
                 wander: Double.random(in: 0...(2 * .pi)),
                 flapPhase: Double.random(in: 0...(2 * .pi)),
                 flapRate: Double.random(in: 3.0...4.5))
        }
        groups.append(FlockGroup(boids: boids, config: config, attractor: center, isMurmuration: true))
    }

    private func disperseMurmurations() {
        for group in groups where group.isMurmuration {
            group.dispersing = true
            let out = randomUnit()
            group.config.behavior = .migrate(SIMD3(out.x, out.y, 0))
            group.config.maxSpeed *= 1.7
            group.config.wWander = 0.3
        }
    }

    private func randomUnit() -> SIMD3<Double> {
        let a = Double.random(in: 0...(2 * .pi))
        return SIMD3(cos(a), sin(a), 0)
    }
}

// MARK: - BirdShape
//
// The distant-gull silhouette: two wing arcs dipping at the body. `flap` swings
// the wings between a down-stroke (0) and an up-stroke (1) — amplitude pumped up
// from the first cut so the beat actually reads at small sizes.

struct BirdShape: Shape {
    var flap: Double

    var animatableData: Double {
        get { flap }
        set { flap = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let x0 = rect.minX, y0 = rect.minY
        let lift = CGFloat(min(max(flap, 0), 1))

        let tipY = y0 + h * (0.72 - 0.50 * lift)        // wingtips swing low → high
        let bodyY = y0 + h * 0.55
        let shoulderY = y0 + h * (0.46 - 0.42 * lift)   // shoulders lead the beat

        let leftTip = CGPoint(x: x0, y: tipY)
        let rightTip = CGPoint(x: x0 + w, y: tipY)
        let body = CGPoint(x: x0 + w * 0.5, y: bodyY)
        let leftShoulder = CGPoint(x: x0 + w * 0.27, y: shoulderY)
        let rightShoulder = CGPoint(x: x0 + w * 0.73, y: shoulderY)

        p.move(to: leftTip)
        p.addQuadCurve(to: body, control: leftShoulder)
        p.addQuadCurve(to: rightTip, control: rightShoulder)
        return p
    }
}

// MARK: - SkyBirdsView

struct SkyBirdsView: View {
    /// Tick only while the host screen is foreground & active (same gate as the
    /// celestial arc). Paused, the sim freezes and stops requesting frames.
    var isActive: Bool
    /// Silhouette colour — pass the theme's `ink` so birds read on light & dark.
    var tint: Color
    /// 0…1 daylight factor (from the real sun): scales ambient opacity and gates
    /// ambient spawning. The murmuration ignores it (it's a deliberate egg moment).
    var daylight: Double
    /// Egg stage 2: while true, a murmuration floods in and swirls; false disperses it.
    var murmuration: Bool

    @State private var flock = Flock()

    var body: some View {
        if BirdSkyConfig.isEnabled {
            TimelineView(.animation(paused: !isActive)) { timeline in
                // Step + draw INSIDE the Canvas, referencing `timeline.date`, so the
                // Canvas genuinely redraws every frame (the loop won't pump if the
                // step is a side-effect on an otherwise-static Canvas). `flock` is a
                // plain reference type, so stepping it isn't SwiftUI state — no
                // "modifying state during update".
                Canvas { ctx, size in
                    flock.advance(to: timeline.date, size: size,
                                  daylight: daylight, murmuration: murmuration)
                    draw(in: ctx, size: size)
                }
            }
            .allowsHitTesting(false)   // scenery; never intercept taps
        }
    }

    private func draw(in ctx: GraphicsContext, size: CGSize) {
        for group in flock.renderGroups {
            for b in group.boids {
                let zNorm = b.pos.z / BirdSkyConfig.depthScale
                let span = lerp(group.config.spanRange.lowerBound, group.config.spanRange.upperBound, zNorm)
                let x = CGFloat(b.pos.x), y = CGFloat(b.pos.y)
                guard x > -span, x < size.width + span, y > -span, y < size.height + span else { continue }

                var opacity = group.config.baseOpacity * (0.55 + 0.45 * Double(zNorm))
                if group.config.respectsDaylight { opacity *= daylight }
                guard opacity > 0.01 else { continue }

                let heading = atan2(b.vel.y, b.vel.x)
                let flap = 0.5 + 0.5 * sin(b.flapPhase)
                let h = span * 0.6

                var g = ctx
                g.translateBy(x: x, y: y)
                g.rotate(by: .radians(heading + .pi / 2))   // point the body along travel
                let rect = CGRect(x: -span / 2, y: -h / 2, width: span, height: h)
                g.stroke(
                    BirdShape(flap: flap).path(in: rect),
                    with: .color(tint.opacity(opacity)),
                    style: StrokeStyle(lineWidth: max(0.7, span * 0.10), lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Previews

#Preview("Bird shape") {
    HStack(spacing: 24) {
        ForEach([0.0, 0.5, 1.0], id: \.self) { f in
            BirdShape(flap: f)
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 40, height: 24)
        }
    }
    .padding()
}
