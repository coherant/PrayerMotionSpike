import SwiftUI
import SalahMotionCore

// Stage 4c: the watch running SalahMotionCore. Constructs a PrayerStateMachine driven by
// the wrist (WristMotionSource) and rendered by the watch shell (WatchGuidanceRenderer) —
// a standalone, phone-free guided/silent salah. The screen binds to the machine's
// @Observable state, exactly like the iPhone views do.
struct GuidedPrayerWatchView: View {
    @State private var motion = WristMotionSource()
    @State private var session: PrayerStateMachine?
    @State private var level: GuidanceLevel = .full
    // Which prayer to practice. The watch can't yet auto-detect the *current* prayer
    // (that needs prayer-times on the wrist — the B4 arc), so default to the user's
    // selected prayer and let them pick.
    @State private var prayer: SalatType = UserPreferences.shared.salatType

    var body: some View {
        Group {
            if let session {
                switch session.status {
                case .running, .cancelled: running(session)
                case .complete:            complete
                case .idle:                idle
                }
            } else {
                idle
            }
        }
        .navigationTitle("Prayer")
    }

    private var idle: some View {
        VStack(spacing: 10) {
            Text("Practice · Farḍ").font(.headline)
            Picker("Prayer", selection: $prayer) {
                ForEach(SalatType.allCases) { p in Text(p.displayName).tag(p) }
            }
            .pickerStyle(.navigationLink)
            Picker("Mode", selection: $level) {
                Text("Guided").tag(GuidanceLevel.full)
                Text("Silent").tag(GuidanceLevel.silent)
            }
            .pickerStyle(.navigationLink)

            // Takbīr to begin — raising the hands to the ears (takbīratul-iḥrām) starts the
            // prayer, the way it actually opens. Unique to the wrist.
            VStack(spacing: 3) {
                Text("🙌").font(.title3).opacity(motion.isTakbir ? 1 : 0.45)
                Text(motion.isTakbir ? "Hold…" : "Takbīr to begin")
                    .font(.caption2)
                    .foregroundStyle(motion.isTakbir ? .green : .secondary)
            }
            .padding(.top, 2)

            Button("Begin \(prayer.displayName)") { begin() }
                .buttonStyle(.bordered)
                .disabled(!motion.isAvailable)
            if !motion.isAvailable {
                Text("Motion unavailable").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .task { motion.start() }                        // classify on idle so we can catch takbīr
        .onChange(of: motion.takbirHeld) { _, held in
            if held, session == nil { begin() }         // opening gesture starts the prayer
        }
    }

    private func running(_ s: PrayerStateMachine) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                if s.unitCount > 1 {
                    Text(s.currentUnitLabel).font(.caption2).foregroundStyle(.secondary)
                }
                Text(s.currentState.displayLabel).font(.headline).multilineTextAlignment(.center)
                if !s.currentState.arabic.isEmpty {
                    Text(s.currentState.arabic).font(.caption)
                }
                if let posture = motion.postureLabel {
                    Text("wrist: \(posture)  gz \(motion.gravityZ, specifier: "%.2f")")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                // Hands-free advance. Double Tap (finger pinch, Series 9 / Ultra 2+) triggers
                // this; a screen tap is the universal fallback. For the taslīm — which the wrist
                // can't sense — this and the du'ā-raise movement close the prayer.
                Button { s.requestManualAdvance() } label: {
                    Label(s.escapeHatchVisible ? "Tap to continue" : "Salām / Advance",
                          systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .doubleTapPrimary()
                Button("End", role: .destructive) { s.cancel() }
                    .font(.caption)
            }
            .padding(.horizontal, 8)
        }
    }

    private var complete: some View {
        VStack(spacing: 10) {
            Text("✅ Complete").font(.headline)
            Button("Done") { session = nil }
                .buttonStyle(.bordered)
        }
    }

    private func begin() {
        // Farḍ only: unitIds: [] → the obligatory unit is always included, sunnah/witr excluded.
        // container: false → a focused practice, no Muezzin frame.
        let s = PrayerStateMachine(
            sequence: GuidedSequenceGenerator.generate(salat: prayer, unitIds: [], container: false),
            guidanceLevel: level,
            motionSource: motion,
            renderer: WatchGuidanceRenderer()
        )
        session = s
        s.start()
    }
}

private extension View {
    /// Bind Apple Watch Double Tap (finger pinch) to this control's action, where available
    /// (watchOS 11+, Series 9 / Ultra 2+). No-op elsewhere — screen tap still works.
    @ViewBuilder func doubleTapPrimary() -> some View {
        if #available(watchOS 11.0, *) { self.handGestureShortcut(.primaryAction) }
        else { self }
    }
}
