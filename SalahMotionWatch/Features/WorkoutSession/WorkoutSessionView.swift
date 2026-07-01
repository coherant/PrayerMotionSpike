import SwiftUI
import HealthKit

struct WorkoutSessionView: View {
    @Environment(WorkoutSessionManager.self) private var sessionManager
    @Environment(MotionManager.self) private var motion

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(sessionManager.isSessionActive ? Color.green : Color.gray)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: sessionManager.isSessionActive ? "waveform" : "pause")
                                .foregroundStyle(.white)
                        }
                    Text(stateLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    infoRow("Type", "Mind & Body")
                    infoRow("Motion", motion.isActive ? "Active" : "Inactive")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                Button(sessionManager.isSessionActive ? "End Session" : "Start Session") {
                    Task {
                        if sessionManager.isSessionActive {
                            await sessionManager.stopSession()
                        } else {
                            await sessionManager.startSession()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(sessionManager.isSessionActive ? .red : .green)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Session")
    }

    private var stateLabel: String {
        switch sessionManager.sessionState {
        case .notStarted: return "Not Started"
        case .running: return "Running"
        case .ended: return "Ended"
        case .paused: return "Paused"
        case .prepared: return "Prepared"
        case .stopped: return "Stopped"
        @unknown default: return "Unknown"
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption)
        }
    }
}
