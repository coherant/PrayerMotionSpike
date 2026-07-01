import SwiftUI

// Placeholder — the watch prayer-times screen (B1/B4). Real content lands once the
// prayer-times/qibla computation is shared to the watch (docs/features/watch).
struct PrayerTimesWatchView: View {
    var body: some View {
        ContentUnavailableView("Prayer Times", systemImage: "clock",
                               description: Text("Coming soon"))
            .navigationTitle("Prayer Times")
    }
}
