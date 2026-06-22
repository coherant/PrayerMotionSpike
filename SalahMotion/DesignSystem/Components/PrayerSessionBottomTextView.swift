import SwiftUI

struct PrayerSessionBottomTextView: View {
    let positionName: String
    let positionMeaning: String
    let recitationText: String
    let instruction: String
    let onEndPrayer: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Position name · meaning
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(positionName)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text("· \(positionMeaning)")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer().frame(height: 10)

            // Recitation
            Text(recitationText)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.white.opacity(0.65))

            Spacer().frame(height: 6)

            // Instruction
            Text(instruction)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.38))
                .kerning(0.4)

            Spacer().frame(height: 20)

            // End prayer
            Button(action: onEndPrayer) {
                Text("END PRAYER")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(.white.opacity(0.28))
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview("Fajr")    { BottomTextPreview(prayerTime: .fajr) }
#Preview("Dhuhr")   { BottomTextPreview(prayerTime: .dhuhr) }
#Preview("Asr")     { BottomTextPreview(prayerTime: .asr) }
#Preview("Maghrib") { BottomTextPreview(prayerTime: .maghrib) }
#Preview("Isha")    { BottomTextPreview(prayerTime: .isha) }

private struct BottomTextPreview: View {
    let prayerTime: PrayerTime
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            PrayerSessionBottomTextView(
                positionName: "Sujood",
                positionMeaning: "Prostration",
                recitationText: "Glory be to Allah the most high",
                instruction: "awaiting motion",
                onEndPrayer: {}
            )
            .padding(.bottom, 40)
        }
    }
}
