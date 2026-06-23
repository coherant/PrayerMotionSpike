import SwiftUI

@main
struct SalahMotionApp: App {
    @State private var router = Router()

    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            AppShell()
                .environment(router)
                .environment(UserPreferences.shared)
        }
    }
}
