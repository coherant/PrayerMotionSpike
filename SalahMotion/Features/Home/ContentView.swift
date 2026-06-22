import SwiftUI

struct ContentView: View {
    private let prayerTime = PrayerTime.current

    var body: some View {
        TabView {
            ReactivePrayerView(prayerTime: prayerTime)
                .tabItem { Label("Guided", systemImage: "moon.stars.fill") }
            CalibrationView()
                .tabItem { Label("Calibration", systemImage: "person.crop.circle.badge.checkmark") }
            GuidedRecordingView()
                .tabItem { Label("Global Calibration", systemImage: "figure.stand") }
        }
    }
}

#Preview {
    ContentView()
}
