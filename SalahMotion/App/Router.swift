import SwiftUI

enum Route: Hashable {
    case home
    case prayerSession
    case settings
    case qiblaCompass
    case onboarding
}

enum AppTab: Hashable {
    case prayerTimes
    case guided
    case calibration
    case globalCalibration
    case settings
}

@Observable
final class Router {
    var path = NavigationPath()
    var selectedTab: AppTab = .prayerTimes

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
