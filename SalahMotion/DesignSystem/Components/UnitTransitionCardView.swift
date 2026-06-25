import SwiftUI

/// Brief "{from} complete — Begin {to}" card shown for ~2s at a unit boundary,
/// while PrayerStateMachine.unitTransition is non-nil. See docs/guided/observances.md §4.
struct UnitTransitionCardView: View {
    let from: String
    let to: String
    let prayerTime: PrayerTime

    private var theme: PrayerTimeTheme { prayerTime.theme }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 14) {
                Text("\(from) complete")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.ink.opacity(0.65))

                Rectangle()
                    .fill(theme.ink.opacity(0.20))
                    .frame(width: 120, height: 1)

                Text("Begin \(to)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(theme.ink)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.ink.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }
}

#Preview("Sunnah → Farḍ") {
    ZStack {
        PrayerTime.fajr.backgroundGradient.ignoresSafeArea()
        UnitTransitionCardView(from: "Sunnah", to: "Farḍ", prayerTime: .fajr)
    }
}

#Preview("Farḍ → Witr") {
    ZStack {
        PrayerTime.isha.backgroundGradient.ignoresSafeArea()
        UnitTransitionCardView(from: "Farḍ", to: "Witr", prayerTime: .isha)
    }
}
