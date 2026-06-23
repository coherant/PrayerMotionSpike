import SwiftUI

// MARK: - Calibration step (8 posture types across the 15-state sequence)

private enum CalibrationStep: Int, CaseIterable {
    case qiyam, ruku, itidal, sujood, julus, tashahhud, tasleemRight, tasleemLeft

    var label: String {
        switch self {
        case .qiyam:        return "Qiyam"
        case .ruku:         return "Rukūʿ"
        case .itidal:       return "Iʿtidāl"
        case .sujood:       return "Sujūd"
        case .julus:        return "Julūs"
        case .tashahhud:    return "Tashahhud"
        case .tasleemRight: return "Right"
        case .tasleemLeft:  return "Left"
        }
    }

    var arabic: String {
        switch self {
        case .qiyam:        return "قِيَام"
        case .ruku:         return "رُكُوع"
        case .itidal:       return "اعتدال"
        case .sujood:       return "سُجُود"
        case .julus:        return "جُلُوس"
        case .tashahhud:    return "تَشَهُّد"
        case .tasleemRight: return "تسليم"
        case .tasleemLeft:  return "تسليم"
        }
    }

    var chip: String {
        switch self {
        case .qiyam:        return "Standing · arms at sides"
        case .ruku:         return "Bowing · hands to the knees"
        case .itidal:       return "Standing · after bowing"
        case .sujood:       return "Prostration · forehead to the ground"
        case .julus:        return "Sitting · upright on knees"
        case .tashahhud:    return "Sitting · finger raised"
        case .tasleemRight: return "Salutation · head right"
        case .tasleemLeft:  return "Salutation · head left"
        }
    }

    // Returns a bundle image name if one exists, otherwise text placeholder is shown
    var imageName: String? {
        switch self {
        case .qiyam:  return "calib-qiyam"
        case .ruku:   return "calib-ruku"
        case .sujood: return "calib-sujud"
        default:      return nil
        }
    }
}

private extension PrayerStateID {
    var calibrationStep: CalibrationStep {
        switch self {
        case .qiyamStart, .qiyamRakat2:
            return .qiyam
        case .rukuFirst, .rukuSecond:
            return .ruku
        case .qiyamAfterRukuFirst, .qiyamAfterRukuSecond:
            return .itidal
        case .sujoodFirst, .sujoodSecond, .sujoodThird, .sujoodFourth:
            return .sujood
        case .julusFirst, .julusSecond:
            return .julus
        case .julusTashahhud:
            return .tashahhud
        case .tasleemRight:
            return .tasleemRight
        case .tasleemLeft:
            return .tasleemLeft
        }
    }
}

// MARK: - Progress arc shape

private struct CaptureArc: Shape {
    var progress: Double
    var animatableData: Double { get { progress } set { progress = newValue } }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: .init(x: rect.midX, y: rect.midY),
                 radius: rect.width / 2,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + 360 * max(0, min(1, progress))),
                 clockwise: false)
        return p
    }
}

// MARK: - Calibration view

struct CalibrationView: View {

    @State private var session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full)
    @State private var calibrationProfile: UserCalibrationProfile?
    @State private var activeProfile: UserCalibrationProfile? = UserCalibrationProfile.load()
    @State private var wavePhase = false

    private let prayerTime = PrayerTime.current
    private var accent: Color { prayerTime.theme.accent }

    private var currentStep: CalibrationStep { session.currentState.id.calibrationStep }

    private var completedSteps: Set<CalibrationStep> {
        var done = Set<CalibrationStep>()
        for i in 0..<session.currentStateIndex {
            done.insert(session.states[i].id.calibrationStep)
        }
        done.remove(currentStep)
        return done
    }

    var body: some View {
        ZStack {
            prayerTime.backgroundGradient.ignoresSafeArea()
            switch session.status {
            case .idle:      idleView
            case .running:   runningView
            case .complete:  completeView
            case .cancelled: cancelledView
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.status)
        .onChange(of: session.status) {
            if session.status == .complete {
                let result = CalibrationAnalyzer(samples: session.sessionSamples).analyze()
                calibrationProfile = result
                if let result { activeProfile = result; result.save() }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accent.opacity(0.10))
                    .frame(width: 120, height: 120)
                Circle()
                    .strokeBorder(accent.opacity(0.28), lineWidth: 1)
                    .frame(width: 120, height: 120)
                Image(systemName: "scope")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(accent)
            }
            .padding(.bottom, 28)

            Text("Tune your movements")
                .font(Typography.display(32, weight: .medium))
                .foregroundStyle(DesignTokens.ink)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            Text("15 positions · 2 rakats · motion capture")
                .font(Typography.ui(14))
                .foregroundStyle(DesignTokens.muted)

            if !session.isAvailable {
                Text("Connect AirPods to begin")
                    .font(Typography.ui(12))
                    .foregroundStyle(accent.opacity(0.8))
                    .padding(.top, 8)
            }

            Spacer()

            if activeProfile != nil {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                    Text("Personal calibration active")
                        .font(Typography.ui(12))
                }
                .foregroundStyle(accent)
                .padding(.bottom, 6)

                Button("Reset to defaults", role: .destructive) {
                    UserCalibrationProfile.reset()
                    activeProfile = nil
                }
                .font(Typography.ui(12))
                .foregroundStyle(DesignTokens.faint)
                .padding(.bottom, 20)
            }

            Button {
                session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full)
                session.start()
            } label: {
                HStack(spacing: 9) {
                    Text("Begin Calibration")
                        .font(Typography.ui(16, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(DesignTokens.darkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: accent.opacity(0.34), radius: 17, y: 12)
            }
            .buttonStyle(.plain)
            .disabled(!session.isAvailable)
            .opacity(session.isAvailable ? 1 : 0.4)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: 0) {
            runningHeader
            Spacer(minLength: 0)
            hatifBar
                .padding(.horizontal, 22)
            Spacer(minLength: 0)
            captureDial
            postureLabel
                .padding(.top, 16)
                .padding(.horizontal, 22)
            Spacer(minLength: 0)
            motionBars
                .padding(.horizontal, 22)
            Spacer(minLength: 0)
            stepperRow
                .padding(.horizontal, 22)
            statusPill
                .padding(.top, 14)
                .padding(.bottom, 32)
        }
        .padding(.top, 54)
    }

    private var runningHeader: some View {
        HStack(spacing: 14) {
            Button { session.cancel() } label: {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#a39db6"))
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("Calibration")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundStyle(accent)
                Text("Tune your movements")
                    .font(Typography.display(26, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
            }

            Spacer()

            Text("\(session.currentStateIndex + 1) / \(session.states.count)")
                .font(Typography.ui(12.5))
                .foregroundStyle(DesignTokens.faint)
                .fixedSize()
        }
        .padding(.horizontal, 22)
    }

    // MARK: Hātif voice bar

    private var hatifBar: some View {
        HStack(spacing: 12) {
            let barHeights: [CGFloat] = [5, 9, 6, 12, 7, 11, 5, 9, 6]
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accent)
                        .frame(width: 2.5, height: h)
                        .scaleEffect(y: session.isSpeaking ? 1.0 : 0.25, anchor: .center)
                        .animation(
                            .easeInOut(duration: 1.2 + Double(i % 3) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: session.isSpeaking
                        )
                }
            }
            .frame(height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text("HĀTIF · GUIDING")
                    .font(Typography.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(accent)
                Text(session.currentState.entrySpeech ?? "")
                    .font(Typography.ui(13))
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accent.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: Capture dial

    private var captureDial: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                .frame(width: 230, height: 230)

            CaptureArc(progress: session.confirmProgress)
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 222, height: 222)
                .animation(.linear(duration: 0.1), value: session.confirmProgress)

            // Ground line
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 140, height: 1)
                .offset(y: 82)

            postureContent(for: currentStep)
        }
        .frame(width: 230, height: 230)
    }

    @ViewBuilder
    private func postureContent(for step: CalibrationStep) -> some View {
        if let name = step.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 118)
        } else {
            VStack(spacing: 4) {
                Text(step.arabic)
                    .font(Typography.arabic(32))
                    .foregroundStyle(accent)
                Text(step.label)
                    .font(Typography.display(15, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
    }

    // MARK: Posture label

    private var postureLabel: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(currentStep.arabic)
                    .font(Typography.arabic(28))
                    .foregroundStyle(DesignTokens.ink)
                Text(currentStep.label)
                    .font(Typography.display(22, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
            Text(currentStep.chip)
                .font(Typography.ui(12))
                .foregroundStyle(DesignTokens.faint)
                .tracking(0.3)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                )
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Motion sampling bars

    private var motionBars: some View {
        VStack(spacing: 6) {
            let heights: [CGFloat] = [8, 14, 10, 18, 12, 16, 9, 13, 8, 15, 10, 17]
            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accent.opacity(0.35 + Double(h) / 60.0))
                        .frame(width: 3, height: h)
                        .scaleEffect(y: wavePhase ? 1.0 : 0.15, anchor: .center)
                        .animation(
                            .easeInOut(duration: 0.55 + Double(i % 4) * 0.15)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.07),
                            value: wavePhase
                        )
                }
            }
            .frame(height: 20)
            .onAppear { wavePhase = true }

            Text("SAMPLING MOTION")
                .font(Typography.eyebrow)
                .tracking(2)
                .foregroundStyle(DesignTokens.faint)
        }
    }

    // MARK: 8-step stepper

    private var stepperRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalibrationStep.allCases.enumerated()), id: \.element.rawValue) { index, step in
                if index > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
                stepperDot(step: step,
                           completed: completedSteps.contains(step),
                           current: step == currentStep)
            }
        }
    }

    private func stepperDot(step: CalibrationStep, completed: Bool, current: Bool) -> some View {
        ZStack {
            Circle()
                .fill(completed ? accent : (current ? Color.clear : Color.white.opacity(0.06)))
                .frame(width: 22, height: 22)

            if current {
                Circle()
                    .strokeBorder(accent, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }

            if completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignTokens.darkOnAccent)
            } else if current {
                Circle().fill(accent).frame(width: 6, height: 6)
            }
        }
    }

    // MARK: Status pill

    private var statusPill: some View {
        let text: String
        if session.isSpeaking {
            text = "Hātif is speaking"
        } else if session.confirmProgress > 0.01 {
            text = "Recording · hold still"
        } else {
            text = "Waiting for movement"
        }
        return Text(text)
            .font(Typography.ui(12, weight: .semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(accent.opacity(0.12))
                    .overlay(Capsule().strokeBorder(accent.opacity(0.3), lineWidth: 1))
            )
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 0) {
            Spacer()

            if calibrationProfile != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(accent)
                    .padding(.bottom, 20)
                Text("Calibration complete")
                    .font(Typography.display(32, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.bottom, 8)
                Text("Your movements have been tuned.")
                    .font(Typography.ui(14))
                    .foregroundStyle(DesignTokens.muted)
            } else {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 72))
                    .foregroundStyle(DesignTokens.faint)
                    .padding(.bottom, 20)
                Text("Could not calibrate")
                    .font(Typography.display(32, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.bottom, 8)
                Text("Not enough motion data was captured.\nPlease try again.")
                    .font(Typography.ui(14))
                    .foregroundStyle(DesignTokens.muted)
                    .multilineTextAlignment(.center)
            }

            if let p = calibrationProfile {
                calibrationResultCard(p)
                    .padding(.top, 28)
                    .padding(.horizontal, 22)
            }

            Spacer()

            Button {
                calibrationProfile = nil
                session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full)
            } label: {
                Text("Done")
                    .font(Typography.ui(16, weight: .bold))
                    .foregroundStyle(DesignTokens.darkOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: accent.opacity(0.34), radius: 17, y: 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
    }

    private func calibrationResultCard(_ p: UserCalibrationProfile) -> some View {
        VStack(spacing: 0) {
            resultRow("Ruku",    String(format: "%.0f° to %.0f°",    p.rukuPitchLow,     p.rukuPitchHigh))
            resultRow("Upright", String(format: "%.0f° to %.0f°",    p.uprightPitchLow,  p.uprightPitchHigh))
            resultRow("Sujood",  String(format: "≤ %.0f° from 180°", p.sujoodRollRadius))
            resultRow("Tasleem", String(format: "≥ %.0f° offset",    p.tasleemYawOffset))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DesignTokens.cardBorder, lineWidth: 1))
        )
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.ui(13))
                .foregroundStyle(DesignTokens.muted)
            Spacer()
            Text(value)
                .font(Typography.ui(13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }

    // MARK: - Cancelled

    private var cancelledView: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "xmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.faint)
                .padding(.bottom, 16)
            Text("Calibration cancelled")
                .font(Typography.display(28, weight: .medium))
                .foregroundStyle(DesignTokens.ink)
                .padding(.bottom, 8)
            Text("Your previous calibration is still active.")
                .font(Typography.ui(13))
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full)
            } label: {
                Text("Try Again")
                    .font(Typography.ui(16, weight: .bold))
                    .foregroundStyle(DesignTokens.darkOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Previews

#Preview("Idle")      { CalibrationView() }
#Preview("Cancelled") {
    let v = CalibrationView()
    return v
}
