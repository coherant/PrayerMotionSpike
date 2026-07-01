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
            Text("Wrist-guided Witr").font(.headline)
            Picker("Mode", selection: $level) {
                Text("Guided").tag(GuidanceLevel.full)
                Text("Silent").tag(GuidanceLevel.silent)
            }
            .pickerStyle(.navigationLink)
            Button("Begin") { begin() }
                .buttonStyle(.borderedProminent)
                .disabled(!motion.isAvailable)
            if !motion.isAvailable {
                Text("Motion unavailable").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
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
                    Text("wrist: \(posture)").font(.caption2).foregroundStyle(.secondary)
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
        let s = PrayerStateMachine(
            sequence: GuidedSequenceGenerator.witrSequence(language: UserPreferences.shared.recitationLanguage),
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
