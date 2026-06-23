import SwiftUI

struct AppShell: View {
    @State private var showingLaunch = true

    var body: some View {
        ZStack {
            TabView {
                PrayerTimesView()
                    .tabItem { Label("Prayer Times", systemImage: "sun.horizon.fill") }
                GuidedPrayerView()
                    .tabItem { Label("Guided", systemImage: "moon.stars.fill") }
                CalibrationView()
                    .tabItem { Label("Calibration", systemImage: "person.crop.circle.badge.checkmark") }
                GlobalCalibrationView()
                    .tabItem { Label("Global Calibration", systemImage: "figure.stand") }
            }

            if showingLaunch {
                LaunchView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingLaunch = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

#Preview {
    AppShell()
}
