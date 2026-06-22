import SwiftUI

struct TrackerPosition: Identifiable, Equatable {
    let id: Int
    let transliteration: String
    let arabic: String
}

struct PositionTrackerView: View {
    let positions: [TrackerPosition]
    let prayerTime: PrayerTime

    private var accent: Color { prayerTime.theme.accent }

    private var visible: [TrackerPosition] {
        Array(positions.suffix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, position in
                let isActive = index == visible.count - 1
                let isFirst  = index == 0
                let dimness  = isActive ? 1.0 : (index == visible.count - 2 ? 0.45 : 0.25)

                HStack(alignment: .top, spacing: 10) {
                    // Dot + connecting line column
                    VStack(spacing: 0) {
                        // Line above (from previous dot)
                        if !isFirst {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 1.5, height: 32)
                        }

                        // Dot
                        ZStack {
                            if isActive {
                                Circle()
                                    .fill(accent.opacity(0.28))
                                    .frame(width: 20, height: 20)
                            }
                            Circle()
                                .fill(isActive ? accent : Color.white.opacity(0.30))
                                .frame(
                                    width:  isActive ? 9 : 5,
                                    height: isActive ? 9 : 5
                                )
                        }
                        .frame(width: 20, height: 20)

                        // Line below (to next dot)
                        if !isActive {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 1.5, height: 32)
                        }
                    }

                    // Labels — aligned to center of dot
                    VStack(alignment: .leading, spacing: 2) {
                        Text(position.transliteration)
                            .font(.system(
                                size: isActive ? 15 : 11,
                                weight: isActive ? .semibold : .regular,
                                design: .serif
                            ))
                            .foregroundStyle(.white.opacity(dimness))
                        Text(position.arabic)
                            .font(.system(size: isActive ? 11 : 9))
                            .foregroundStyle(.white.opacity(dimness * 0.65))
                    }
                    .padding(.top, isFirst ? 4 : 36)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.45), value: visible.map(\.id))
    }
}

#Preview("Fajr")    { TrackerPreview(prayerTime: .fajr) }
#Preview("Dhuhr")   { TrackerPreview(prayerTime: .dhuhr) }
#Preview("Asr")     { TrackerPreview(prayerTime: .asr) }
#Preview("Maghrib") { TrackerPreview(prayerTime: .maghrib) }
#Preview("Isha")    { TrackerPreview(prayerTime: .isha) }

private struct TrackerPreview: View {
    let prayerTime: PrayerTime
    private let samplePositions = [
        TrackerPosition(id: 0, transliteration: "Qiyam",  arabic: "قِيَام"),
        TrackerPosition(id: 1, transliteration: "Ruku",   arabic: "رُكُوع"),
        TrackerPosition(id: 2, transliteration: "Sujood", arabic: "سُجُود"),
    ]
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            PositionTrackerView(positions: samplePositions, prayerTime: prayerTime)
                .padding(.leading, 24)
        }
    }
}
