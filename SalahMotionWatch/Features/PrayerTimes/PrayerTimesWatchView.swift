import SwiftUI

// Prayer Times — computed on the wrist from the shared Adhan calc (WatchPrayerTimes).
// Shows the next prayer + countdown and today's five times, the next one emphasised.
struct PrayerTimesWatchView: View {
    @State private var engine = WatchPrayerTimes()

    var body: some View {
        List {
            if let next = engine.nextPrayer, let date = engine.nextPrayerDate {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 9, weight: .semibold)).tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(label(next)).font(.system(size: 24, weight: .semibold))
                    Text(date, style: .relative)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(Array(engine.ordered.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(label(item.prayer))
                        Spacer()
                        Text(item.date, style: .time).foregroundStyle(.secondary)
                    }
                    .fontWeight(item.prayer == engine.nextPrayer ? .semibold : .regular)
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
