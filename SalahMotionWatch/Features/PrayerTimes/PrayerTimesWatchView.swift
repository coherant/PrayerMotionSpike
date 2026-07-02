import SwiftUI

// Prayer Times — computed on the wrist from the shared Adhan calc (WatchPrayerTimes).
// Shows the next prayer + countdown and today's five times, the next one emphasised.
struct PrayerTimesWatchView: View {
    private let engine = WatchPrayerTimes.shared

    var body: some View {
        List {
            if let next = engine.nextPrayer, let date = engine.nextPrayerDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(Typography.ui(9, weight: .semibold)).tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(label(next)).font(Typography.display(26, weight: .semibold))
                    Text(date, style: .relative)
                        .font(Typography.ui(12)).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(Array(engine.ordered.enumerated()), id: \.offset) { _, item in
                    let isNext = item.prayer == engine.nextPrayer
                    HStack {
                        Text(label(item.prayer))
                            .font(Typography.display(17, weight: isNext ? .semibold : .medium))
                        Spacer()
                        Text(item.date, style: .time)
                            .font(Typography.ui(14, weight: isNext ? .semibold : .regular))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Prayer Times")
        .onAppear { engine.refreshIfNeeded() }
    }

    private func label(_ p: Prayer) -> String {
        switch p {
        case .fajr:    "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr:   "Dhuhr"
        case .asr:     "Asr"
        case .maghrib: "Maghrib"
        case .isha:    "Isha"
        }
    }
}
