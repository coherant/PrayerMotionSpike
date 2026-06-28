import SwiftUI

// MARK: - Launch / Splash Screen
// Source: docs/features/launch-screen/launch.md
// Shown immediately after the system launch screen.
// Theme driven by PrayerTime.current.

struct LaunchView: View {
    let onComplete: () -> Void

    // Live atmospheric theme (same engine as the app), so the splash shows the
    // current period — including the new Asr palette and the dusk blue hour —
    // rather than a stale hardcoded set. Snapshotted once for the ~4s splash.
    private let blend = DayTheme.blend()
    private var prayerTime: PrayerTime { blend.dominant }

    // Intro animation flags
    @State private var showHorizon    = false
    @State private var showLine       = false
    @State private var showInvocation = false
    @State private var showOrb        = false
    @State private var showWordmark   = false
    @State private var showSeparator  = false
    @State private var showAyah       = false
    @State private var showLoader     = false
    @State private var showStatus     = false

    // Ambient loop flags
    @State private var isPulsing    = false
    @State private var isTwinkling  = false
    @State private var showStars    = false
    @State private var lineHeight: CGFloat = 0

    private var theme: PrayerTimeTheme { blend.theme }
    private var accent: Color { theme.accent }
    private var starCount: Int {
        switch prayerTime {
        case .fajr:    return 34
        case .dhuhr:   return 0
        case .asr:     return 12
        case .maghrib: return 19
        case .isha:    return 55
        }
    }

    var body: some View {
        ZStack {
            // Background
            background

            VStack(spacing: 0) {
                Spacer()

                // Descending light line
                lightLine
                    .opacity(showLine ? 1 : 0)

                // Invocation
                invocation
                    .opacity(showInvocation ? 1 : 0)
                    .padding(.bottom, 18)

                // Orb
                orbView
                    .scaleEffect(showOrb ? 1 : 0.6)
                    .opacity(showOrb ? 1 : 0)
                    .padding(.bottom, 24)

                // Wordmark
                wordmark
                    .offset(y: showWordmark ? 0 : 12)
                    .opacity(showWordmark ? 1 : 0)
                    .padding(.bottom, 16)

                // Separator
                separator
                    .opacity(showSeparator ? 1 : 0)
                    .padding(.bottom, 20)

                // Qur'an ayah
                ayahBlock
                    .opacity(showAyah ? 1 : 0)

                Spacer()

                // Day-arc loader
                loaderSection
                    .opacity(showLoader ? 1 : 0)
                    .padding(.bottom, 52)
            }

            // Stars are generated once (held in StarfieldView's @State) and fade
            // in via an explicit, value-scoped animation. This keeps the ambient
            // intro `withAnimation` transactions from animating their positions —
            // which is what made them fly around the orb before settling.
            if starCount > 0 {
                StarfieldView(
                    count: starCount,
                    isDhuhr: prayerTime == .dhuhr,
                    accent: accent
                )
                .opacity(showStars ? 1 : 0)
                .animation(.easeIn(duration: 1.2), value: showStars)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Horizon glow
            VStack {
                Spacer()
                RadialGradient(
                    colors: [accent.opacity(0.35), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
                .frame(height: 120)
                .blur(radius: 20)
                .opacity(showHorizon ? 1 : 0)
            }
            .ignoresSafeArea()
        }
        .onAppear { runIntroSequence() }
    }

    // MARK: - Background

    private var background: some View {
        // A centred glow built from the LIVE theme: the warm horizon tone glows
        // from the upper-centre out to the dark sky tone at the edges. Because it
        // reads from `theme` (the interpolated blend), the splash automatically
        // shows the new Asr palette, the dusk blue hour, and the cross-fade.
        RadialGradient(
            colors: [
                theme.gradientBottom,
                Color.lerp(theme.gradientTop, theme.gradientBottom, 0.45),
                theme.gradientTop,
            ],
            center: UnitPoint(x: 0.5, y: 0.28),
            startRadius: 0,
            endRadius: 600
        )
        .ignoresSafeArea()
    }

    // MARK: - Light line

    private var lightLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, accent.opacity(0.6), accent.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: lineHeight)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Invocation

    private var invocation: some View {
        Text("أَقِمِ الصَّلَاةَ")
            .font(Typography.arabic(20))
            .environment(\.layoutDirection, .rightToLeft)
            .foregroundStyle(accent)
            .shadow(color: accent.opacity(0.8), radius: 12)
    }

    // MARK: - Orb

    private var orbView: some View {
        ZStack {
            // Soft blurred outer ring
            Circle()
                .stroke(accent.opacity(0.22), lineWidth: 1)
                .frame(width: 196 + 44, height: 196 + 44)
                .blur(radius: 2.5)

            // Pulse halo
            Circle()
                .stroke(accent.opacity(isPulsing ? 0.0 : 0.4), lineWidth: 1)
                .frame(width: 196 + 4, height: 196 + 4)
                .scaleEffect(isPulsing ? 1.18 : 1.0)
                .animation(.easeOut(duration: 4.5).repeatForever(autoreverses: false), value: isPulsing)

            // Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.9), Color.white.opacity(0.05), .clear],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0,
                        endRadius: 82
                    )
                )
                .frame(width: 196 - 32, height: 196 - 32)
                .blur(radius: 4)
                .scaleEffect(isPulsing ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: isPulsing)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.orbA, theme.orbB],
                        center: UnitPoint(x: 0.42, y: 0.36),
                        startRadius: 0,
                        endRadius: 72
                    )
                )
                .frame(width: 92, height: 92)
                .shadow(color: accent.opacity(0.9), radius: 32)
                .scaleEffect(isPulsing ? 1.06 : 0.94)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: isPulsing)
        }
        .frame(width: 244, height: 244)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        HStack(spacing: 0) {
            Text("Salah")
                .font(Typography.display(41, weight: .medium))
                .foregroundStyle(theme.ink)
            Text("Motion")
                .font(Typography.display(41, weight: .medium))
                .foregroundStyle(theme.muted)
        }
    }

    // MARK: - Separator

    private var separator: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(height: 0.5)
            Text("◆")
                .font(.system(size: 6))
                .foregroundStyle(accent)
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Ayah block

    private var ayahBlock: some View {
        VStack(spacing: 8) {
            // Arabic with ornamental brackets
            HStack(spacing: 4) {
                Text("﴿")
                    .font(Typography.arabic(19))
                    .foregroundStyle(accent)
                Text("أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ")
                    .font(Typography.arabic(17))
                    .foregroundStyle(theme.ink)
                    .environment(\.layoutDirection, .rightToLeft)
                Text("﴾")
                    .font(Typography.arabic(19))
                    .foregroundStyle(accent)
            }

            // Translation
            Text("\"…in the remembrance of Allah do hearts find rest.\"")
                .font(Typography.display(15, weight: .regular))
                .italic()
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Citation
            Text("SŪRAT AR-RAʿD · 13:28")
                .font(Typography.ui(10.5))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(theme.faint)
        }
    }

    // MARK: - Loader

    private var loaderSection: some View {
        VStack(spacing: 10) {
            Text("Preparing your space")
                .font(Typography.ui(11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(theme.faint)

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(prayerTime == .dhuhr
                          ? Color(hex: "#22323f").opacity(0.16)
                          : Color.white.opacity(0.10))
                    .frame(width: 156, height: 3)

                // Fill — all 5 prayer colours in sequence
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#eaa9b2"),
                                Color(hex: "#d99a2a"),
                                Color(hex: "#f3b24c"),
                                Color(hex: "#f4a86a"),
                                Color(hex: "#9a86c7"),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: showLoader ? 156 : 0, height: 3)
                    .animation(.timingCurve(0.4, 0, 0.2, 1, duration: 2.3).delay(0.55), value: showLoader)
            }
        }
    }

    // MARK: - Intro sequence

    private func runIntroSequence() {
        // Ambient loops — start immediately
        isPulsing   = true
        isTwinkling = true

        // Fade stars in (positions are fixed; only opacity animates, via the
        // value-scoped .animation on the starfield — never the intro transactions)
        showStars = true

        // Sequenced intro per launch.md §6
        withAnimation(.easeIn(duration: 1.6).delay(0.3))  { showHorizon    = true }
        withAnimation(.easeOut(duration: 1.4).delay(0.2)) { lineHeight      = 60 }
        withAnimation(.easeIn(duration: 0.8).delay(0.45)) { showLoader      = true }
        withAnimation(.easeIn(duration: 1.0).delay(0.35)) { showInvocation  = true }
        withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 1.3).delay(0.1)) { showOrb = true }
        withAnimation(.easeOut(duration: 0.95).delay(0.75)) { showWordmark  = true }
        withAnimation(.easeIn(duration: 0.9).delay(1.05))  { showSeparator  = true }
        withAnimation(.easeIn(duration: 0.9).delay(1.20))  { showAyah       = true }
        withAnimation(.easeIn(duration: 1.0).delay(1.50))  { showStatus     = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            onComplete()
        }
    }
}

// StarfieldView moved to DesignSystem/Components/StarfieldView.swift (shared with
// the Isha atmospheric theme).

// MARK: - Preview

#Preview("Isha")    { LaunchView(onComplete: {}) }
#Preview("Fajr")    { LaunchView(onComplete: {}).onAppear { } }
#Preview("Dhuhr")   { LaunchView(onComplete: {}) }
#Preview("Maghrib") { LaunchView(onComplete: {}) }
