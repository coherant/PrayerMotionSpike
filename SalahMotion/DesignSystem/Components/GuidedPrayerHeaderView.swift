import SwiftUI

struct GuidedPrayerHeaderView: View {
    @Binding var isSilenced: Bool
    let currentRakat: Int
    let totalRakat: Int
    let prayerTime: PrayerTime
    // Unit context — shown only for multi-unit observances (unitCount > 1).
    var unitLabel: String = ""
    var unitIndex: Int = 0   // 0-based
    var unitCount: Int = 1

    private var theme: PrayerTimeTheme { prayerTime.theme }
    private var showsUnit: Bool { unitCount > 1 }

    var body: some View {
        HStack(alignment: .center) {
            Button {
                isSilenced.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isSilenced ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13))
                    Text(isSilenced ? "SILENCE ON" : "SILENCE OFF")
                        .eyebrowStyle()
                }
                .foregroundStyle(theme.ink.opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 8) {
                    Text(showsUnit
                         ? "\(unitLabel) · Rak'ah \(currentRakat) / \(totalRakat)"
                         : "Rak'ah \(currentRakat) / \(totalRakat)")
                        .font(Typography.labelSm)
                        .foregroundStyle(theme.ink.opacity(0.55))

                    HStack(spacing: 4) {
                        ForEach(1...max(1, totalRakat), id: \.self) { i in
                            Circle()
                                .fill(i <= currentRakat
                                      ? theme.ink.opacity(0.80)
                                      : theme.ink.opacity(0.20))
                                .frame(width: 5, height: 5)
                        }
                    }
                }

                if showsUnit {
                    Text("unit \(unitIndex + 1) of \(unitCount)")
                        .font(Typography.labelSm)
                        .foregroundStyle(theme.ink.opacity(0.40))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview("Fajr")    { HeaderPreview(prayerTime: .fajr,    silenced: true) }
#Preview("Dhuhr")   { HeaderPreview(prayerTime: .dhuhr,   silenced: false) }
#Preview("Maghrib") { HeaderPreview(prayerTime: .maghrib, silenced: true) }
#Preview("Isha")    { HeaderPreview(prayerTime: .isha,    silenced: false) }

private struct HeaderPreview: View {
    let prayerTime: PrayerTime
    @State var silenced: Bool
    var body: some View {
        ZStack(alignment: .top) {
            prayerTime.backgroundGradient.ignoresSafeArea()
            VStack {
                GuidedPrayerHeaderView(
                    isSilenced: $silenced,
                    currentRakat: 1,
                    totalRakat: 2,
                    prayerTime: prayerTime
                )
                Spacer()
            }
        }
    }
}
