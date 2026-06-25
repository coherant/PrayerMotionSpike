import SwiftUI

struct AppShell: View {
    @State private var showingLaunch = true
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        ZStack {
            TabView(selection: $router.selectedTab) {
                PrayerTimesView()
                    .tabItem { Label("Prayer Times", systemImage: "sun.horizon.fill") }
                    .tag(AppTab.prayerTimes)
                GuidedPrayerView()
                    .tabItem { Label("Guided", systemImage: "moon.stars.fill") }
                    .tag(AppTab.guided)
                CalibrationView()
                    .tabItem { Label("Calibration", systemImage: "person.crop.circle.badge.checkmark") }
                    .tag(AppTab.calibration)
                // REMOVED FROM TAB BAR (kept implementation): the Global Calibration tab.
                // `GlobalCalibrationView` and `AppTab.globalCalibration` still exist — to
                // restore, re-add the tab item below:
                //   GlobalCalibrationView()
                //       .tabItem { Label("Global Calibration", systemImage: "figure.stand") }
                //       .tag(AppTab.globalCalibration)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(AppTab.settings)
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
