import SwiftUI
import SpriteKit
import UIKit

// MARK: - WeatherLayerView
//
// The simulated/native weather visuals, driven by a canonical `WeatherState`
// (docs/features/weather/SPEC.md §4). Composites, back-to-front:
//   • clouds / fog   — SwiftUI `Canvas` (soft, painterly, drift)
//   • precipitation  — SpriteKit `SKEmitterNode` via `SpriteView` (rain/snow/hail),
//                      density & speed scaled by `state.intensity`
//   • lightning      — a timed SwiftUI flash for thunderstorms
//
// View-only; no provider/network. `isActive` gates every animator (mirrors the
// celestial/birds layers) so it freezes off-tab. `tint` is the silhouette/particle
// colour — pass the theme `ink` at fusion time so it reads on light & dark skies.
//
// Deferred to Stage 5 (polish): a Metal `Shader` rain-on-glass / heat-shimmer accent
// (needs a `.metal` file). The structure leaves room for it as a top overlay.

struct WeatherLayerView: View {
    let state: WeatherState
    var isActive: Bool = true
    var tint: Color = .white

    var body: some View {
        ZStack {
            if state.cloudCover > 0.15 {   // clear/sunny (≈0.05) stays a clean sky
                CloudsView(cloudCover: state.cloudCover, tint: tint, isActive: isActive)
            }
            if state.condition == .fog {
                FogVeil(intensity: state.intensity, tint: tint, isActive: isActive)
            }
            if let kind = PrecipKind(state.condition), state.intensity > 0.001 {
                PrecipitationView(kind: kind, intensity: state.intensity, tint: tint, isActive: isActive)
            }
            if state.condition == .thunderstorm {
                LightningView(isActive: isActive, tint: tint)
            }
        }
        .allowsHitTesting(false)   // scenery; never intercept taps
    }
}

// MARK: - Precipitation kind

private enum PrecipKind: Equatable {
    case rain, snow, hail

    init?(_ c: WeatherCondition) {
        switch c {
        case .drizzle, .rain, .heavyRain, .thunderstorm, .sleet: self = .rain
        case .snow: self = .snow
        case .hail: self = .hail
        default:    return nil   // clear / partlyCloudy / cloudy / fog / wind
        }
    }
}

// MARK: - Precipitation (SpriteKit)

private struct PrecipitationView: View {
    let kind: PrecipKind
    let intensity: Double
    let tint: Color
    let isActive: Bool

    @State private var scene = PrecipitationScene()

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .onAppear { refresh(geo.size) }
                .onChange(of: geo.size) { refresh(geo.size) }
                .onChange(of: intensity) { refresh(geo.size) }
                .onChange(of: kind) { refresh(geo.size) }
                .onChange(of: isActive) { scene.isPaused = !isActive }
        }
        .allowsHitTesting(false)
    }

    private func refresh(_ size: CGSize) {
        scene.isPaused = !isActive
        scene.apply(kind: kind, intensity: intensity, size: size, color: UIColor(tint))
    }
}

private final class PrecipitationScene: SKScene {
    private var emitter: SKEmitterNode?

    override init() {
        super.init(size: CGSize(width: 1, height: 1))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    func apply(kind: PrecipKind, intensity: Double, size: CGSize, color: UIColor) {
        guard size.width > 1, size.height > 1 else { return }
        self.size = size
        emitter?.removeFromParent()
        let e = PrecipitationScene.makeEmitter(kind: kind, intensity: intensity, size: size, color: color)
        addChild(e)
        emitter = e
    }

    private static func makeEmitter(kind: PrecipKind, intensity: Double,
                                    size: CGSize, color: UIColor) -> SKEmitterNode {
        let h = size.height, w = size.width
        let e = SKEmitterNode()
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .alpha
        // SKScene is y-up: spawn just above the top edge, fall downward (−y).
        e.position = CGPoint(x: w / 2, y: h + 30)
        e.particlePositionRange = CGVector(dx: w + 80, dy: 0)
        e.emissionAngle = -.pi / 2

        switch kind {
        case .rain:
            let speed: CGFloat = 1000
            e.particleTexture = PrecipTexture.rain
            e.particleSpeed = speed; e.particleSpeedRange = 150
            e.emissionAngleRange = 0.06
            e.particleBirthRate = CGFloat(60 + intensity * 440)
            e.particleLifetime = (h + 80) / speed + 0.3; e.particleLifetimeRange = 0.2
            e.particleAlpha = 0.5; e.particleAlphaRange = 0.25
            e.particleScale = 1.0; e.particleScaleRange = 0.4
        case .snow:
            let speed: CGFloat = 90
            e.particleTexture = PrecipTexture.snow
            e.particleSpeed = speed; e.particleSpeedRange = 35
            e.emissionAngleRange = 0.5
            e.particleBirthRate = CGFloat(20 + intensity * 160)
            e.particleLifetime = (h + 80) / speed + 1; e.particleLifetimeRange = 1
            e.particleAlpha = 0.85; e.particleAlphaRange = 0.2
            e.particleScale = 0.8; e.particleScaleRange = 0.5
            e.particleRotationSpeed = 0.6
        case .hail:
            let speed: CGFloat = 1200
            e.particleTexture = PrecipTexture.hail
            e.particleSpeed = speed; e.particleSpeedRange = 200
            e.emissionAngleRange = 0.04
            e.particleBirthRate = CGFloat(40 + intensity * 260)
            e.particleLifetime = (h + 80) / speed + 0.3
            e.particleAlpha = 0.9; e.particleAlphaRange = 0.1
            e.particleScale = 0.9; e.particleScaleRange = 0.3
        }
        // Pre-fill so the sky isn't empty for the first fall-through.
        e.advanceSimulationTime(Double(e.particleLifetime))
        return e
    }
}

// MARK: - Particle textures (generated once)

private enum PrecipTexture {
    static let rain = streak(width: 2.5, height: 16)
    static let snow = dot(diameter: 7, soft: true)
    static let hail = dot(diameter: 5, soft: false)

    private static func streak(width: CGFloat, height: CGFloat) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: width / 2).fill()
        }
        return SKTexture(image: image)
    }

    private static func dot(diameter: CGFloat, soft: Bool) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            if soft {
                let center = CGPoint(x: diameter / 2, y: diameter / 2)
                let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
                if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors, locations: [0, 1]) {
                    ctx.cgContext.drawRadialGradient(grad, startCenter: center, startRadius: 0,
                                                     endCenter: center, endRadius: diameter / 2, options: [])
                }
            } else {
                UIColor.white.setFill()
                UIBezierPath(ovalIn: rect).fill()
            }
        }
        return SKTexture(image: image)
    }
}

// MARK: - Clouds (Canvas)

private struct CloudsView: View {
    let cloudCover: Double
    let tint: Color
    let isActive: Bool

    @State private var puffs: [CloudPuff] = []

    // Tier 2 — parallax depth: three bands, each drawn in its own layer with its
    // own blur. Far = blurrier/slower/fainter, near = sharper/faster/opaque.
    private static let bandBlur: [CGFloat] = [30, 20, 11]

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { tl in
            Canvas { ctx, size in
                guard !puffs.isEmpty else { return }
                let t = tl.date.timeIntervalSinceReferenceDate
                let visible = Int((Double(puffs.count) * cloudCover).rounded())
                guard visible > 0 else { return }
                let shown = puffs.prefix(visible)
                for band in 0..<Self.bandBlur.count {        // far → near (back to front)
                    let layer = shown.filter { min(2, Int($0.z * 3)) == band }
                    guard !layer.isEmpty else { continue }
                    ctx.drawLayer { lctx in
                        lctx.addFilter(.blur(radius: Self.bandBlur[band]))
                        for p in layer {
                            p.draw(in: lctx, size: size, t: t, tint: tint, cover: cloudCover)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { if puffs.isEmpty { puffs = CloudPuff.generate(count: 9) } }
    }
}

private struct CloudPuff {
    let z: Double          // 0 = far … 1 = near (parallax depth)
    let baseY: Double      // fraction of height (0 = top)
    let scale: Double
    let phase: Double      // 0…1 start offset
    let opacity: Double

    static func generate(count: Int) -> [CloudPuff] {
        (0..<count).map { _ in
            let z = Double.random(in: 0...1)
            return CloudPuff(z: z,
                             baseY: .random(in: 0.03...0.42),
                             scale: 0.55 + z * 1.05,            // near = larger
                             phase: .random(in: 0...1),
                             opacity: .random(in: 0.45...0.85))
        }
    }

    func draw(in ctx: GraphicsContext, size: CGSize, t: Double, tint: Color, cover: Double) {
        let span = size.width + 360
        let speed = 3 + z * 14                                  // near = faster drift
        let x = (phase * span + t * speed).truncatingRemainder(dividingBy: span) - 180
        let y = baseY * size.height
        let r = 30.0 * scale
        let depthAlpha = 0.45 + 0.55 * z                       // near = more opaque
        let alpha = opacity * depthAlpha * min(1.0, 0.3 + cover) * 0.5
        let color = GraphicsContext.Shading.color(tint.opacity(alpha))
        // A puff = a few overlapping ellipses (blurred by the layer filter).
        let lobes: [(dx: Double, dy: Double, r: Double)] = [
            (0, 0, r), (r * 0.9, 6, r * 0.8), (-r * 0.9, 8, r * 0.75),
            (r * 0.4, -r * 0.5, r * 0.7), (-r * 0.5, -r * 0.4, r * 0.65),
        ]
        for l in lobes {
            let rect = CGRect(x: x + l.dx - l.r, y: y + l.dy - l.r, width: l.r * 2, height: l.r * 2)
            ctx.fill(Path(ellipseIn: rect), with: color)
        }
    }
}

// MARK: - Fog veil (Canvas)

private struct FogVeil: View {
    let intensity: Double
    let tint: Color
    let isActive: Bool

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                ctx.addFilter(.blur(radius: 40))
                for i in 0..<3 {
                    let y = size.height * (0.30 + 0.20 * Double(i))
                    let drift = sin(t * 0.05 + Double(i)) * 40
                    let rect = CGRect(x: -100 + drift, y: y, width: size.width + 200, height: 120)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 60),
                             with: .color(tint.opacity(0.10 * intensity + 0.06)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Lightning (drawn bolt + ambient flash)
//
// Each strike paints a freshly-generated forked bolt over a soft full-screen
// flash. Two techniques from how games render lightning (Ryan Juckett's "2D
// lightning"):
//   • Geometry: midpoint displacement — the start→tip line is recursively
//     subdivided, each midpoint pushed perpendicular by a halving amount, so
//     the bolt is self-similar/jagged at every scale, with a few angled forks.
//   • Glow: NOT a Gaussian blur (which smears a thin line into a grey smudge).
//     Instead each channel is stroked in several additive (`.plusLighter`)
//     passes — wide+faint up to a crisp hot core — so light accumulates toward
//     white and reads as an electric halo.
// The bolt snaps in at full brightness and decays, like a real discharge.

private struct LightningView: View {
    let isActive: Bool
    var tint: Color = .white

    @State private var flash = 0.0       // bolt-strike flash (sharp, bright)
    @State private var sheen = 0.0       // distant sheet-lightning glow (soft, no bolt)
    @State private var boltOpacity = 0.0
    @State private var bolt = Bolt.random()

    // Additive stroke passes, widest/faintest → narrow hot core. The outermost
    // halo carries the sky `tint`; the inner passes are white-hot.
    private static let passes: [(width: CGFloat, opacity: Double, tinted: Bool)] = [
        (14, 0.07, true), (9, 0.12, false), (5, 0.20, false), (2.6, 0.40, false), (1.4, 0.95, false)
    ]

    var body: some View {
        ZStack {
            // Distant sheet lightning — a soft, tinted sky glow with no visible
            // bolt (the strike is below the horizon). Sits behind the sharp flash.
            Rectangle()
                .fill(tint)
                .opacity(sheen)

            // Ambient sky flash — the room lighting up from a nearby strike.
            Rectangle()
                .fill(Color.white)
                .opacity(flash)

            // The bolt itself, drawn in screen space with additive glow.
            Canvas { ctx, size in
                ctx.blendMode = .plusLighter
                for channel in bolt.channels {
                    let path = bolt.path(for: channel, in: size)
                    for pass in Self.passes {
                        let base = pass.tinted ? tint : .white
                        ctx.stroke(path, with: .color(base.opacity(pass.opacity * channel.brightness)),
                                   style: StrokeStyle(lineWidth: pass.width, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .opacity(boltOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task(id: isActive) {
            guard isActive else { return }
            // Open with a strike so entering a storm reads instantly, then settle
            // into a randomized cadence.
            await strike()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(.random(in: 4...12)))
                if Task.isCancelled { break }
                await strike()
            }
        }
        // Distant sheet flashes run on their own cadence so they layer in
        // between the bolt strikes rather than replacing them.
        .task(id: isActive) {
            guard isActive else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(.random(in: 3...9)))
                if Task.isCancelled { break }
                await sheetFlash()
            }
        }
    }

    @MainActor private func sheetFlash() async {
        // Soft bloom up, slow fade — distant and diffuse, no sharp edge.
        withAnimation(.easeOut(duration: 0.18)) { sheen = .random(in: 0.16...0.30) }
        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.easeInOut(duration: 0.55)) { sheen = 0 }
        if Bool.random() {   // occasional faint flicker on the way down
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.12)) { sheen = .random(in: 0.10...0.18) }
            try? await Task.sleep(for: .milliseconds(90))
            withAnimation(.easeInOut(duration: 0.45)) { sheen = 0 }
        }
    }

    @MainActor private func strike() async {
        bolt = .random()
        // Bolt snaps in instantly, flash blooms a touch behind it.
        boltOpacity = 1
        withAnimation(.easeOut(duration: 0.08)) { flash = 0.5 }
        try? await Task.sleep(for: .milliseconds(90))
        withAnimation(.easeIn(duration: 0.25)) { flash = 0 }
        withAnimation(.easeIn(duration: 0.22)) { boltOpacity = 0 }
        if Bool.random() {   // occasional double-strike
            try? await Task.sleep(for: .milliseconds(120))
            bolt = .random()
            boltOpacity = 1
            withAnimation(.easeOut(duration: 0.06)) { flash = 0.38 }
            try? await Task.sleep(for: .milliseconds(70))
            withAnimation(.easeIn(duration: 0.30)) { flash = 0 }
            withAnimation(.easeIn(duration: 0.26)) { boltOpacity = 0 }
        }
    }
}

// MARK: - Bolt geometry (midpoint displacement)
//
// Normalized (0...1) channels so a single generated bolt scales to any canvas.
// The main channel runs top→tip; forks branch off mid-bolt at an angle and are
// dimmer. Built by recursive midpoint displacement (perpendicular push that
// halves each generation → fractal jaggedness).

private struct Bolt {
    struct Channel { let points: [CGPoint]; let brightness: Double }
    let channels: [Channel]   // main channel first, then forks

    func path(for channel: Channel, in size: CGSize) -> Path {
        var p = Path()
        p.addLines(channel.points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) })
        return p
    }

    static func random() -> Bolt {
        let start = CGPoint(x: .random(in: 0.35...0.65), y: 0)
        let tip   = CGPoint(x: .random(in: 0.28...0.72), y: .random(in: 0.70...0.90))
        var forks: [Channel] = []
        let main = displace(from: start, to: tip, generations: 6, amplitude: 0.10,
                            brightness: 1, forks: &forks)
        return Bolt(channels: [Channel(points: main, brightness: 1)] + forks)
    }

    /// Recursive midpoint displacement. Returns the displaced polyline; appends
    /// any spawned forks (themselves displaced, dimmer, never re-branching).
    private static func displace(from start: CGPoint, to end: CGPoint,
                                 generations: Int, amplitude: Double,
                                 brightness: Double, forks: inout [Channel]) -> [CGPoint] {
        var points = [start, end]
        var amp = amplitude
        for gen in 0..<generations {
            var next: [CGPoint] = [points[0]]
            for i in 0..<(points.count - 1) {
                let a = points[i], b = points[i + 1]
                let dx = b.x - a.x, dy = b.y - a.y
                let len = max(hypot(dx, dy), 0.0001)
                let nx = -dy / len, ny = dx / len            // unit perpendicular
                let d = Double.random(in: -amp...amp)
                let mid = CGPoint(x: (a.x + b.x) / 2 + nx * d,
                                  y: (a.y + b.y) / 2 + ny * d)
                next.append(mid)
                next.append(b)

                // Spawn a fork off this midpoint — only on main channel (brightness
                // ≈ 1), after a couple of generations, capped to keep it legible.
                if brightness > 0.9, gen >= 2, forks.count < 5, Double.random(in: 0...1) < 0.25 {
                    let angle = atan2(dy, dx) + (Bool.random() ? 1 : -1) * Double.random(in: 0.4...0.75)
                    let bl = len * Double.random(in: 0.5...0.9)
                    let fEnd = CGPoint(x: mid.x + cos(angle) * bl, y: mid.y + sin(angle) * bl)
                    let fPts = displace(from: mid, to: fEnd, generations: 3, amplitude: amp * 0.7,
                                        brightness: brightness * 0.5, forks: &forks)
                    forks.append(Channel(points: fPts, brightness: 0.55))
                }
            }
            points = next
            amp *= 0.55   // halve-ish each generation → self-similar detail
        }
        return points
    }
}

// MARK: - Previews

#Preview("Weather — cycle") {
    WeatherPreviewHost()
}

private struct WeatherPreviewHost: View {
    @State private var condition: WeatherCondition = .rain
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#14223f"), Color(hex: "#243b63")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            WeatherLayerView(state: .sample(condition), tint: .white)
            VStack {
                Spacer()
                Picker("", selection: $condition) {
                    ForEach(WeatherCondition.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .background(.ultraThinMaterial)
            }
        }
    }
}
