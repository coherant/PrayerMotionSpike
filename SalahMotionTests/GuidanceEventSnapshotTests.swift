//
//  GuidanceEventSnapshotTests.swift
//  SalahMotionTests
//
//  Golden snapshot of the GuidanceEvent stream PrayerStateMachine emits at runtime —
//  the OUT-seam net (Stage 3c, docs/features/watch/REFACTOR-PLAN.md). The [PrayerState]
//  snapshot (GuidedSnapshotTests) freezes the machine's INPUT (the generated sequence);
//  this freezes what it actually EMITS through the seam as it runs. Behavior-preserving
//  refactors of the runner/OUT-seam must leave this byte-identical.
//
//  Determinism: driven through a scripted MotionSource (no real sensor) by spamming
//  manual-advance to skip the motion waits; a recording renderer captures the stream
//  instead of playing audio; languages pinned to .english.
//

import Testing
import Foundation
import SalahMotionCore

// A GuidanceRenderer that records the event stream instead of rendering it. Returns
// instantly (like a silent shell), so the run is fast and deterministic.
@MainActor
final class RecordingGuidanceRenderer: GuidanceRenderer {
    private(set) var log: [String] = []
    var isSpeaking: Bool { false }
    func stop() {}
    func render(_ event: GuidanceEvent) async {
        switch event {
        case .line(let l):
            let id = l.clipID?.rawValue ?? l.audioKey ?? "-"
            log.append("line     id=\(id) text=\(q(l.utterance))")
        case .utterance(let u):
            log.append("utterance role=\(role(u)) id=\(u.idLabel ?? "-") text=\(q(u.text(in: .english)))")
        case .call(let id):
            log.append("call     id=\(id.rawValue)")
        case .cue:
            log.append("cue")
        }
    }
    private func role(_ u: Utterance) -> String {
        switch u {
        case .guidance:   return "instruct"
        case .recitation: return "recite"
        case .plain:      return "plain"
        }
    }
    private func q(_ s: String) -> String { "\"\(s)\"" }
}

// A MotionSource that reports nothing — the machine advances purely via manual-advance.
@MainActor
final class ScriptedMotionSource: MotionSource {
    var isAvailable: Bool { true }
    var smoothedPitch: Double { 0 }
    var smoothedRoll: Double { 0 }
    var smoothedYaw: Double { 0 }
    func start(onRawSample: (@MainActor @Sendable (Double, Double, Double) -> Void)?) {}
    func stop() {}
}

@MainActor
struct GuidanceEventSnapshotTests {

    @Test func guidanceEventStreamMatchesSnapshot() async throws {
        UserPreferences.shared.guidanceLanguage = .english
        UserPreferences.shared.recitationLanguage = .english
        UserPreferences.shared.pace = .fast   // shortest auto-phase dwells (manual-advance can't skip them)

        // A real prefix of the standalone Witr sequence — covers every event kind
        // (entry/exit utterances, prayer lines, the cue, motion transitions) while keeping
        // the runtime bounded. The full-sequence structure is already frozen by the
        // [PrayerState] snapshot; this net is for the runtime EMISSION mapping.
        let sequence = Array(GuidedSequenceGenerator.witrSequence(language: .english).prefix(6))

        let recorder = RecordingGuidanceRenderer()
        let machine = PrayerStateMachine(
            sequence: sequence,
            guidanceLevel: .full,
            useDefaultThresholds: true,
            motionSource: ScriptedMotionSource(),
            renderer: recorder
        )

        machine.start()
        let deadline = Date().addingTimeInterval(45)
        while machine.status == .running, Date() < deadline {
            machine.requestManualAdvance()
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(machine.status == .complete)

        let actual = "=== witr opening GuidanceEvent stream (\(recorder.log.count) events) ===\n"
            + recorder.log.enumerated().map { "[\($0)] \($1)" }.joined(separator: "\n") + "\n"

        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().appendingPathComponent("__Snapshots__")
        let ref = dir.appendingPathComponent("guidance-events.txt")
        let fm = FileManager.default
        if !fm.fileExists(atPath: ref.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try actual.write(to: ref, atomically: true, encoding: .utf8)
            Issue.record("Baseline GuidanceEvent snapshot written to \(ref.path) — re-run to verify.")
            return
        }
        let expected = try String(contentsOf: ref, encoding: .utf8)
        if actual != expected {
            let actualURL = dir.appendingPathComponent("guidance-events.actual.txt")
            try? actual.write(to: actualURL, atomically: true, encoding: .utf8)
            Issue.record("GuidanceEvent snapshot mismatch — wrote actual to \(actualURL.path).")
        }
        #expect(actual == expected)
    }
}
