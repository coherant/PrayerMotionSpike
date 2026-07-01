import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Shell-side keep-awake. Prevents the screen dimming while a guided/silent/calibration
// session is running. Moved out of PrayerStateMachine (Stage 3b-iii) so the core carries
// no UIKit — the view reacts to the machine's `status` instead.
private struct KeepScreenAwake: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            #if canImport(UIKit)
            .onChange(of: active, initial: true) { _, on in
                UIApplication.shared.isIdleTimerDisabled = on
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            #endif
    }
}

extension View {
    /// Keep the screen awake while `active` (e.g. `session.status == .running`).
    func keepScreenAwake(_ active: Bool) -> some View {
        modifier(KeepScreenAwake(active: active))
    }
}
