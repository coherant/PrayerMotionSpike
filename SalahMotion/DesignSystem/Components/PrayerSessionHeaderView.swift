import SwiftUI

struct PrayerSessionHeaderView: View {
    @Binding var isSilenced: Bool
    let currentRakat: Int
    let totalRakat: Int
    let prayerTime: PrayerTime

    var body: some View {
        HStack(alignment: .center) {
            // Silence toggle
            Button {
                isSilenced.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isSilenced ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13))
                    Text(isSilenced ? "SILENCE ON" : "SILENCE OFF")
                        .font(.system(size: 10, weight: .medium))
                        .kerning(1.2)
                }
                .foregroundStyle(.white.opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            // Rak'ah counter + progress dots
            HStack(spacing: 8) {
                Text("Rak'ah \(currentRakat) / \(totalRakat)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))

                HStack(spacing: 4) {
                    ForEach(1...max(1, totalRakat), id: \.self) { i in
                        Circle()
                            .fill(i <= currentRakat
                                  ? Color.white.opacity(0.80)
                                  : Color.white.opacity(0.20))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}

#Preview("Fajr · silenced")    { HeaderPreview(prayerTime: .fajr,    silenced: true) }
#Preview("Dhuhr · active")     { HeaderPreview(prayerTime: .dhuhr,   silenced: false) }
#Preview("Asr · active")       { HeaderPreview(prayerTime: .asr,     silenced: false) }
#Preview("Maghrib · silenced") { HeaderPreview(prayerTime: .maghrib, silenced: true) }
#Preview("Isha · active")      { HeaderPreview(prayerTime: .isha,    silenced: false) }

private struct HeaderPreview: View {
    let prayerTime: PrayerTime
    @State var silenced: Bool
    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                PrayerSessionHeaderView(
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
