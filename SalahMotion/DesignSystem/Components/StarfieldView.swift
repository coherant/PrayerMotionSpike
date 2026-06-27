import SwiftUI

// MARK: - StarfieldView
//
// Fixed twinkling starfield used by the launch screen and the Isha (night)
// atmospheric theme. It is a BACKGROUND layer (non-interactive, sits behind all
// content). Positions are generated ONCE and held in @State so they never
// re-randomize on re-render — the recurring "stars fly around the orb" bug.
// Only OPACITY animates, via a value-scoped `.animation` keyed on `twinkling`
// (set once in onAppear) so parent re-renders never restart it.

struct StarfieldView: View {
    let isDhuhr: Bool
    let accent: Color

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let baseOpacity: Double
        let isSparkle: Bool
        let twinkleDuration: Double
        let twinkleDelay: Double
    }

    @State private var stars: [Star]
    @State private var twinkling = false

    init(count: Int, isDhuhr: Bool = false, accent: Color = .white) {
        self.isDhuhr = isDhuhr
        self.accent  = accent
        var rng = SystemRandomNumberGenerator()
        _stars = State(initialValue: (0..<count).map { i in
            Star(
                id: i,
                x: CGFloat.random(in: 0.05...0.95, using: &rng),
                y: CGFloat.random(in: 0.04...0.62, using: &rng),
                size: CGFloat.random(in: 1.0...2.6, using: &rng),
                baseOpacity: Double.random(in: 0.6...1.0, using: &rng),
                isSparkle: i < (count / 6),
                twinkleDuration: Double.random(in: 1.8...3.8, using: &rng),
                twinkleDelay: Double.random(in: 0...2.5, using: &rng)
            )
        })
    }

    private var starColor: Color {
        isDhuhr ? Color(hex: "#22323f") : Color(hex: "#f4f1fa")
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                starShape(star)
                    .position(x: star.x * geo.size.width,
                              y: star.y * geo.size.height)
                    .opacity(twinkling ? star.baseOpacity : star.baseOpacity * 0.3)
                    .animation(
                        .easeInOut(duration: star.twinkleDuration)
                            .repeatForever(autoreverses: true)
                            .delay(star.twinkleDelay),
                        value: twinkling
                    )
            }
        }
        .allowsHitTesting(false)   // pure background — never intercept touches
        .onAppear { twinkling = true }
    }

    // Brighter stars get four-point diffraction spikes so they read as actual
    // stars rather than flat dots; the rest stay simple points.
    @ViewBuilder
    private func starShape(_ star: Star) -> some View {
        if star.isSparkle {
            ZStack {
                Circle()
                    .fill(starColor)
                    .frame(width: star.size, height: star.size)
                Capsule()
                    .fill(starColor.opacity(0.45))
                    .frame(width: 0.8, height: star.size * 3.6)
                Capsule()
                    .fill(starColor.opacity(0.45))
                    .frame(width: star.size * 3.6, height: 0.8)
            }
            .blur(radius: 0.2)
        } else {
            Circle()
                .fill(starColor)
                .frame(width: star.size, height: star.size)
        }
    }
}
