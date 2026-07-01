import Foundation

// MARK: - Session sample

public struct SessionSample {
    public let timestamp: Double
    public let stateID: String
    public let pitch: Double
    public let roll: Double
    public let yaw: Double
}

// MARK: - State Machine

@MainActor
@Observable
public final class PrayerStateMachine {

    public enum Status: Equatable { case idle, running, complete, cancelled }

    public struct UnitTransition: Equatable { public let from: String; public let to: String }

    public private(set) var status: Status = .idle
    // Non-nil only while the ~2s unit-boundary card is showing (observance with >1 unit).
    public private(set) var unitTransition: UnitTransition? = nil
    private let unitTransitionHold: Double = 2.0
    public private(set) var currentStateIndex: Int = 0
    public private(set) var states: [PrayerState]
    public private(set) var visitedStates: [PrayerState] = []
    public private(set) var confirmProgress: Double = 0
    public private(set) var pitch: Double = 0
    public private(set) var roll:  Double = 0
    public private(set) var yaw:   Double = 0

    private let renderer: GuidanceRenderer   // OUT seam — injected (iPhone = AudioGuidanceRenderer)
    private let detector: MotionSource       // IN seam  — injected (iPhone = HeadphoneMotionDetector)
    private var thresholds: MotionThresholds

    private var qiyamYawBaseline: Double? = nil
    private var sessionTask: Task<Void, Never>?
    public private(set) var sessionSamples: [SessionSample] = []
    private var sessionStartDate: Date?
    private let participantName: String
    private let holdWindow: Double = 1.5
    /// Interim dwell for a container `.listen` row until Stage 3 binds the Muezzin's voice
    /// (then the dwell becomes the recitation's own length). Tap advances early regardless.
    private let containerListenHold: Double = 4.0

    public var isAvailable: Bool  { detector.isAvailable }
    public var isSpeaking: Bool   { renderer.isSpeaking }
    public var currentState: PrayerState { states[currentStateIndex] }
    public var currentRakat: Int  { currentState.rakatNumber }
    // Rakat numbering resets per unit, so totalRakat is the current unit's rakat count.
    public var totalRakat: Int {
        states.filter { $0.unitIndex == currentState.unitIndex }.map(\.rakatNumber).max() ?? 1
    }

    // Unit identity (observance chaining)
    public var currentUnitIndex: Int  { currentState.unitIndex }
    public var currentUnitLabel: String { currentState.unitLabel }
    public var unitCount: Int { (states.map(\.unitIndex).max() ?? 0) + 1 }

    public private(set) var guidanceLevel: GuidanceLevel

    // MARK: - Silent Mode (the body is the clock — docs/guided/CONGREGATIONAL-CONTAINER.md §3)
    // The voice is withdrawn; advancement is purely the worshipper's own movement, patient
    // and indefinite (no reprompts, no fallback advance). The one transition the sensor
    // can't see — standing up from sitting — is bridged by a short recitation-sized dwell.
    private var isSilent: Bool { guidanceLevel == .silent }
    /// After this long held in one posture with no confirmed movement, the silent-mode
    /// "Tap to continue" escape hatch appears.
    private let escapeHatchDelay: Double = 60
    /// UI binds this to show/hide the "Tap to continue" control (silent mode only).
    public private(set) var escapeHatchVisible: Bool = false
    /// Set by the UI tap; consumed by the wait loop to advance to the next posture.
    private var manualAdvanceRequested = false
    public func requestManualAdvance() { manualAdvanceRequested = true }

    // MARK: - Tasbīḥ counter (container `.count` rows — CONGREGATIONAL-CONTAINER.md §4)
    /// Non-nil only during a `.count` dhikr phase: the number of repetitions still remaining.
    /// The UI renders the counter and calls `tapTasbih()` once per dhikr; the runner advances
    /// when it reaches 0. Reset to nil between phases.
    public private(set) var tasbihRemaining: Int? = nil
    public func tapTasbih() {
        guard let remaining = tasbihRemaining, remaining > 0 else { return }
        tasbihRemaining = remaining - 1
    }

    /// Postures where the head is already upright at rest (seated). A following `.upright`
    /// (stand-up) trigger is therefore invisible to head-attitude detection — bridge it
    /// with a timed dwell rather than waiting for a movement that can't be sensed.
    private func isSeatedUpright(_ state: PrayerState) -> Bool {
        switch state.id {
        case .julusShort, .julusFull, .tasleemRight, .tasleemLeft,
             .r1JulusBetween, .r2JulusBetween, .r3JulusBetween, .r4JulusBetween:
            return true
        default:
            return false
        }
    }

    public init(sequence: [PrayerState] = GuidedSequenceGenerator.generate(),
         guidanceLevel: GuidanceLevel = UserPreferences.shared.guidanceLevel,
         participantName: String = "",
         useDefaultThresholds: Bool = false,
         motionSource: MotionSource,
         renderer: GuidanceRenderer) {
        states = sequence
        self.guidanceLevel = guidanceLevel
        self.participantName = participantName
        self.thresholds = MotionThresholds(profile: useDefaultThresholds ? nil : UserCalibrationProfile.load())
        self.detector = motionSource
        self.renderer = renderer
    }

    public func start() {
        guard isAvailable, status == .idle else { return }
        sessionSamples = []
        visitedStates  = []
        unitTransition = nil
        escapeHatchVisible = false
        manualAdvanceRequested = false
        sessionStartDate = Date()
        qiyamYawBaseline = nil
        startMotionUpdates()
        status = .running
        sessionTask = Task { [weak self] in await self?.runStateMachine() }
    }

    public func cancel() {
        sessionTask?.cancel()
        unitTransition = nil
        escapeHatchVisible = false
        tasbihRemaining = nil
        renderer.stop()
        detector.stop()
        status = .cancelled
    }

    // MARK: - Motion updates

    /// Whether the current motion satisfies `trigger`. If the source detects its own posture
    /// transitions (wrist), trust it; otherwise fall back to threshold detection on the raw
    /// pitch/roll/yaw stream (AirPods). Behavior-preserving for the iPhone: HeadphoneMotionDetector
    /// returns `currentTrigger == nil`, so this is exactly `thresholds.isSatisfied(...)` as before.
    private func satisfies(_ trigger: MotionTrigger, target: DetectedPosture?) -> Bool {
        // Taslīm head turns: no source can report them as a posture — a wrist stands in with
        // the du'ā-raise movement; a head source detects the yaw via thresholds.
        if trigger == .headTurnRight || trigger == .headTurnLeft {
            if detector.reportsPosture || detector.currentTrigger != nil { return detector.isMoving }
            return thresholds.isSatisfied(trigger, pitch: pitch, roll: roll, yaw: yaw,
                                          yawBaseline: qiyamYawBaseline)
        }
        // Posture-reporting source (wrist): require the ACTUAL target posture — so standing up
        // from sujūd gates on *standing*, not on merely leaving the floor to sitting height.
        if detector.reportsPosture, let posture = detector.currentPosture, let target {
            return posture == target
        }
        // Coarse self-detecting source: match the posture-transition trigger.
        if let detected = detector.currentTrigger { return detected == trigger }
        // Head geometry (AirPods): threshold detection on the raw pitch/roll/yaw stream.
        return thresholds.isSatisfied(trigger, pitch: pitch, roll: roll, yaw: yaw,
                                      yawBaseline: qiyamYawBaseline)
    }

    private func startMotionUpdates() {
        detector.start { [weak self] p, r, y in
            guard let self else { return }
            self.pitch = self.detector.smoothedPitch
            self.roll  = self.detector.smoothedRoll
            self.yaw   = self.detector.smoothedYaw
            let elapsed = Date().timeIntervalSince(self.sessionStartDate ?? Date())
            let stateID = self.states[self.currentStateIndex].id.rawValue
            self.sessionSamples.append(SessionSample(
                timestamp: elapsed, stateID: stateID, pitch: p, roll: r, yaw: y
            ))
        }
    }

    // MARK: - State machine loop

    @MainActor
    private func runStateMachine() async {
        let sessionStart = Date()

        for (index, state) in states.enumerated() {
            guard !Task.isCancelled else { break }
            currentStateIndex = index
            visitedStates.append(state)

            // Unit boundary — show a brief silent "X complete — Begin Y" card before
            // the next unit's I-24 opener runs (see observances.md §4).
            if index > 0, states[index - 1].unitIndex != state.unitIndex {
                unitTransition = UnitTransition(from: states[index - 1].unitLabel,
                                                to: state.unitLabel)
                print("[PrayerSM] ⟂ Unit boundary: \(unitTransition!.from) → \(unitTransition!.to)")
                try? await Task.sleep(for: .seconds(unitTransitionHold))
                unitTransition = nil
                guard !Task.isCancelled else { break }
            }

            print(String(format: "[PrayerSM] ▶ %d/%d %@ (%@) t=%.1fs",
                         index + 1, states.count, state.id.rawValue, state.mode.rawValue,
                         Date().timeIntervalSince(sessionStart)))

            // Container (Muezzin) rows are exempt from Silent Mode — the frame is meant to be
            // heard. Everything else in Silent Mode runs through runSilentPhase. See §4.
            if isSilent && !state.isContainer {
                await runSilentPhase(state, index: index)
            } else {
                switch state.mode {
                case .auto:        await runAutoPhase(state)
                case .timed:       await runTimedPhase(state)
                case .motion:      await runMotionPhase(state)
                case .timedMotion: await runTimedMotionPhase(state)
                case .listen:      await runListenPhase(state)
                case .count:       await runCountPhase(state)
                }
            }
        }

        detector.stop()
        if !Task.isCancelled {
            saveSession()
            status = .complete
        }
        print("[PrayerSM] ✅ Session ended — status: \(status)")
    }

    // MARK: - Silent phase runner

    /// Silent Mode runs every in-salah state through here (overriding the per-mode runners).
    /// The orb shows the posture/recitation text (display-only) and the state dwells until
    /// the worshipper makes the *departure* movement — the next state's trigger — patiently
    /// and indefinitely. The lone exception is the seated→stand transition the sensor can't
    /// see, bridged by a short recitation-sized dwell. No audio. See CONGREGATIONAL-CONTAINER.md §3.
    @MainActor
    private func runSilentPhase(_ state: PrayerState, index: Int) async {
        let isLast = index == states.count - 1
        let nextTrigger = isLast ? nil : states[index + 1].motionTrigger

        if isLast {
            // Final taslīm — the prayer is complete; brief close, then end.
            await timedSilentDwell(state)
        } else if nextTrigger == .upright && isSeatedUpright(state) && !detector.reportsPosture {
            // Invisible sit→stand (middle tashahhud → next rakʿah, or unit boundary) — only
            // for head geometry, which can't see it. A wrist source CAN, so it falls through
            // to confirmMotion and waits for the actual standing posture.
            await timedSilentDwell(state)
        } else {
            // Taslīm baseline (Silent): here the departure trigger *is* the first turn, so the
            // current state (julusFull, final sitting) is forward-facing right now. Capture the
            // reference before the wait; the next state (tasleemRight → headTurnLeft) keeps it.
            // See the non-silent twin in runMotionPhase and CONGREGATIONAL-CONTAINER.md §6.
            if nextTrigger == .headTurnRight {
                qiyamYawBaseline = yaw
                print(String(format: "[PrayerSM] 📐 Taslīm baseline: %.1f° (%@)", yaw, state.id.rawValue))
            }
            // Visible departure — wait, indefinitely, for the worshipper to move on.
            await confirmMotion(trigger: nextTrigger,
                                target: isLast ? nil : states[index + 1].expectedPosture,
                                reprompt: nil,
                                repromptInterval: state.repromptInterval,
                                maxReprompts: nil,
                                showProgressDuringWait: false,
                                stateID: state.id.rawValue)
        }
    }

    /// A short dwell sized to the seated recitation (sum of the state's prayer durations,
    /// with a floor), used only where a movement can't be sensed. A tap advances early.
    @MainActor
    private func timedSilentDwell(_ state: PrayerState) async {
        let pace = UserPreferences.shared.pace
        let recitation = state.prayers.reduce(0.0) { $0 + $1.duration.seconds(pace: pace) }
        let dwell = max(recitation, 2.0)
        let start = Date()
        while !Task.isCancelled {
            if manualAdvanceRequested { manualAdvanceRequested = false; return }
            if Date().timeIntervalSince(start) >= dwell { return }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: - Container (Muezzin) runners
    // The congregational frame around the salah — exempt from Silent Mode (meant to be heard).
    // Stage 2 builds these as structural shells: NOTHING is voiced yet (voice binding is
    // Stage 3). `.listen` dwells on an interim hold; `.count` drives the tasbīḥ counter.
    // See docs/guided/CONGREGATIONAL-CONTAINER.md §4.

    /// A single call/recitation (adhān, iqāma, boundary du'ā, āyat al-Kursī, ṣalawāt, closing).
    /// The Muezzin voices the call via the current TTS (the call's transliteration, spoken in
    /// the user's language voice — consistent with the in-salah pipeline, which speaks the
    /// romanized utterance, not Arabic script). A tap advances early; the row otherwise
    /// advances when the speech completes. With no text it falls back to `containerListenHold`.
    /// (Persona-specific Muezzin voices are still Stage 3 — this is the generic TTS tier.)
    @MainActor
    private func runListenPhase(_ state: PrayerState) async {
        escapeHatchVisible = true
        defer { escapeHatchVisible = false }
        if await speakContainerCall(state) { return }   // false = no text → dwell below
        guard let id = state.callID, !CallLibrary.text(id, .arabic).isEmpty else {
            let start = Date()
            while !Task.isCancelled {
                if manualAdvanceRequested { manualAdvanceRequested = false; return }
                if Date().timeIntervalSince(start) >= containerListenHold { return }
                try? await Task.sleep(for: .milliseconds(50))
            }
            return
        }
    }

    /// A counted dhikr — the Muezzin voices the phrase once, then the worshipper repeats to the
    /// call's count via the tasbīḥ counter. The UI renders `tasbihRemaining` and calls
    /// `tapTasbih()` per repetition; advance when it reaches 0. A "tap to continue" also
    /// advances. A count of 0 degrades to a listen.
    @MainActor
    private func runCountPhase(_ state: PrayerState) async {
        let total = state.callID.map { CallLibrary.count($0) } ?? 0
        guard total > 0 else { await runListenPhase(state); return }
        tasbihRemaining = total
        escapeHatchVisible = true
        defer { tasbihRemaining = nil; escapeHatchVisible = false }
        if await speakContainerCall(state) { return }
        while !Task.isCancelled {
            if manualAdvanceRequested { manualAdvanceRequested = false; return }
            if (tasbihRemaining ?? 0) <= 0 { return }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    /// Voices the container call via the renderer (awaited to completion). A "tap to
    /// continue" that lands during it is consumed here (returns true → caller advances)
    /// so it never leaks into the next row.
    @MainActor
    private func speakContainerCall(_ state: PrayerState) async -> Bool {
        guard let id = state.callID else { return false }
        await renderer.render(.call(id))
        if manualAdvanceRequested { manualAdvanceRequested = false; return true }
        return Task.isCancelled
    }

    // MARK: - Phase runners

    /// Voices one prayer line via the OUT seam — the renderer resolves clip vs TTS and
    /// language, and returns when the line has been heard in full (guided timing).
    @MainActor
    private func utter(_ line: PrayerLine) async {
        await renderer.render(.line(line))
    }

    /// Voices a non-prayer line (entry / exit / reprompt) via the OUT seam.
    @MainActor
    private func utter(_ u: Utterance) async {
        await renderer.render(.utterance(u))
    }

    @MainActor
    private func runAutoPhase(_ state: PrayerState) async {
        let pace = UserPreferences.shared.pace
        if let speech = state.entrySpeech { await utter(speech) }
        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            await utter(prayer)
            guard !Task.isCancelled else { return }
            let d = prayer.duration.seconds(pace: pace)
            if d > 0 { try? await Task.sleep(for: .seconds(d)) }
        }
        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await utter(speech) }
    }

    @MainActor
    private func runTimedPhase(_ state: PrayerState) async {
        let pace = UserPreferences.shared.pace
        if guidanceLevel.playsEntryGuidance, let speech = state.entrySpeech {
            await utter(speech)
        }
        guard !Task.isCancelled else { return }
        if !state.prayers.isEmpty { await renderer.render(.cue) }
        if guidanceLevel.playsPrayers {
            for prayer in state.prayers {
                guard !Task.isCancelled else { return }
                await utter(prayer)
                guard !Task.isCancelled else { return }
                let duration = prayer.duration.seconds(pace: pace)
                let start = Date()
                while !Task.isCancelled {
                    let elapsed = Date().timeIntervalSince(start)
                    confirmProgress = min(elapsed / duration, 1.0)
                    if elapsed >= duration { break }
                    try? await Task.sleep(for: .milliseconds(50))
                }
                confirmProgress = 0
            }
        }
        guard !Task.isCancelled else { return }
        if guidanceLevel.playsPrayers, let speech = state.exitSpeech {
            await utter(speech)
        }
    }

    @MainActor
    private func runMotionPhase(_ state: PrayerState) async {
        let pace = UserPreferences.shared.pace
        // Taslīm is a yaw delta from facing-forward. Capture the forward reference here, at the
        // final sitting the instant before the *first* turn — close to use, after the two
        // sujoods that would otherwise drift the heading, and before any entry cue could prompt
        // an early turn. tasleemLeft keeps this same baseline (head already turned by then).
        if state.motionTrigger == .headTurnRight {
            qiyamYawBaseline = yaw
            print(String(format: "[PrayerSM] 📐 Taslīm baseline: %.1f° (%@)", yaw, state.id.rawValue))
        }
        if guidanceLevel.playsEntryGuidance, let speech = state.entrySpeech {
            await utter(speech)
        }
        guard !Task.isCancelled else { return }
        await waitForMotion(state)
        guard !Task.isCancelled else { return }
        if guidanceLevel.playsPrayers {
            for prayer in state.prayers {
                guard !Task.isCancelled else { return }
                await utter(prayer)
                guard !Task.isCancelled else { return }
                let holdDuration = prayer.duration.seconds(pace: pace)
                if holdDuration > 0 {
                    let holdStart = Date()
                    while !Task.isCancelled {
                        let elapsed = Date().timeIntervalSince(holdStart)
                        confirmProgress = min(elapsed / holdDuration, 1.0)
                        if elapsed >= holdDuration { break }
                        try? await Task.sleep(for: .milliseconds(50))
                    }
                    confirmProgress = 0
                }
            }
            guard !Task.isCancelled else { return }
            if let speech = state.exitSpeech { await utter(speech) }
        }
    }

    @MainActor
    private func runTimedMotionPhase(_ state: PrayerState) async {
        let pace = UserPreferences.shared.pace
        if let speech = state.entrySpeech { await utter(speech) }
        guard !Task.isCancelled else { return }
        if !state.prayers.isEmpty { await renderer.render(.cue) }

        var motionHoldStart: Date? = nil
        var lastRepromptAt = Date()

        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            await utter(prayer)
            guard !Task.isCancelled else { return }

            let phaseDuration = prayer.duration.seconds(pace: pace)
            if phaseDuration > 0 {
                let prayerStart = Date()
                while !Task.isCancelled {
                    let elapsed = Date().timeIntervalSince(prayerStart)
                    confirmProgress = min(elapsed / phaseDuration, 1.0)
                    if elapsed >= phaseDuration { break }

                    if let trigger = state.motionTrigger {
                        if satisfies(trigger, target: state.expectedPosture) {
                            if motionHoldStart == nil {
                                motionHoldStart = Date()
                                print(String(format: "[PrayerSM] ◌ Motion: %@ p:%.1f° r:%.1f°",
                                             state.id.rawValue, pitch, roll))
                            }
                            let held = Date().timeIntervalSince(motionHoldStart!)
                            if held >= holdWindow {
                                print(String(format: "[PrayerSM] ✓ Confirmed: %@ held=%.2fs",
                                             state.id.rawValue, held))
                            }
                        } else {
                            motionHoldStart = nil
                        }

                        if Date().timeIntervalSince(lastRepromptAt) >= state.repromptInterval,
                           let reprompt = state.repromptAudio,
                           motionHoldStart == nil {
                            print("[PrayerSM] ⏰ Reprompt: \(state.id.rawValue)")
                            await utter(reprompt)
                            lastRepromptAt = Date()
                        }
                    }

                    try? await Task.sleep(for: .milliseconds(50))
                }
                confirmProgress = 0
            }
        }

        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await utter(speech) }
    }

    // MARK: - Motion waiting

    @MainActor
    private func waitForMotion(_ state: PrayerState) async {
        await confirmMotion(trigger: state.motionTrigger,
                            target: state.expectedPosture,
                            reprompt: state.repromptAudio,
                            repromptInterval: state.repromptInterval,
                            maxReprompts: state.maxReprompts,
                            showProgressDuringWait: state.showProgressDuringWait,
                            stateID: state.id.rawValue)
    }

    /// Core motion-confirm wait, shared by `.motion` phases (voiced) and the silent runner.
    /// Returns when `trigger` is held for `holdWindow`, when the UI requests a manual
    /// advance, or — voiced only — after `maxReprompts` fallbacks. Silent mode: no reprompt
    /// audio, no fallback advance, waits indefinitely, and surfaces the escape hatch after
    /// `escapeHatchDelay`.
    @MainActor
    private func confirmMotion(trigger: MotionTrigger?,
                               target: DetectedPosture? = nil,
                               reprompt: Utterance?,
                               repromptInterval: Double,
                               maxReprompts: Int?,
                               showProgressDuringWait: Bool,
                               stateID: String) async {
        manualAdvanceRequested = false
        defer { escapeHatchVisible = false; confirmProgress = 0 }

        guard let trigger else { return }

        let waitStart = Date()
        var holdStart: Date? = nil
        var lastRepromptAt = Date()
        var repromptCount = 0

        while !Task.isCancelled {
            if manualAdvanceRequested {
                manualAdvanceRequested = false
                print("[PrayerSM] 👆 Manual advance: \(stateID)")
                return
            }

            if isSilent {
                escapeHatchVisible = Date().timeIntervalSince(waitStart) >= escapeHatchDelay
                confirmProgress = 0
            } else {
                let elapsed = Date().timeIntervalSince(lastRepromptAt)
                confirmProgress = showProgressDuringWait ? min(elapsed / repromptInterval, 1.0) : 0
            }

            if satisfies(trigger, target: target) {
                if holdStart == nil { holdStart = Date() }
                if Date().timeIntervalSince(holdStart!) >= holdWindow {
                    print(String(format: "[PrayerSM] ✓ Motion confirmed: %@", stateID))
                    return
                }
            } else {
                holdStart = nil
                if !isSilent,
                   Date().timeIntervalSince(lastRepromptAt) >= repromptInterval,
                   let reprompt {
                    repromptCount += 1
                    print("[PrayerSM] ⏰ Reprompt \(repromptCount): \(stateID)")
                    await utter(reprompt)
                    lastRepromptAt = Date()
                    if let max = maxReprompts, repromptCount >= max {
                        print("[PrayerSM] ⏭ Fallback advance after \(repromptCount): \(stateID)")
                        return
                    }
                }
            }

            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: - Session saving

    private func saveSession() {
        guard !sessionSamples.isEmpty else { return }
        let isCalibration = !participantName.isEmpty
        let filename: String
        var lines: [String]

        if isCalibration {
            let slug = participantName
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ",", with: "")
            filename = "prayer_calibration_\(slug)_\(Int(Date().timeIntervalSince1970)).csv"
            let csvName = participantName.replacingOccurrences(of: ",", with: "")
            lines = ["participant,timestamp_s,state_id,pitch_deg,roll_deg,yaw_deg"]
            for s in sessionSamples {
                lines.append(String(format: "%@,%.4f,%@,%.4f,%.4f,%.4f",
                                    csvName, s.timestamp, s.stateID, s.pitch, s.roll, s.yaw))
            }
        } else {
            filename = "prayer_session_\(Int(Date().timeIntervalSince1970)).csv"
            lines = ["timestamp_s,state_id,pitch_deg,roll_deg,yaw_deg"]
            for s in sessionSamples {
                lines.append(String(format: "%.4f,%@,%.4f,%.4f,%.4f",
                                    s.timestamp, s.stateID, s.pitch, s.roll, s.yaw))
            }
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("[PrayerSM] 💾 Saved: \(filename) (\(sessionSamples.count) samples)")
        } catch {
            print("[PrayerSM] ❌ Save failed: \(error)")
        }
    }
}
