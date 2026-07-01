import SwiftUI

struct StateMachineView: View {
    @Environment(MotionManager.self) private var motion
    @State private var history: [PositionReading] = []
    @State private var current: PrayerPosition = .unknown

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(current.emoji).font(.largeTitle)
                    Text(current.displayName).font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Transitions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    if history.isEmpty {
                        Text("No transitions yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(history) { reading in
                            HStack {
                                Text(reading.position.emoji)
                                Text(reading.position.displayName).font(.caption)
                                Spacer()
                                Text(reading.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("State Machine")
        .onChange(of: motion.latestSample) { _, sample in
            guard let position = sample?.detectedPosition, position != current else { return }
            current = position
            history.insert(PositionReading(position: position), at: 0)
            if history.count > 20 { history.removeLast() }
        }
    }
}
