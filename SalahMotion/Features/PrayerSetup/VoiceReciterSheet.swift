import SwiftUI
import SalahMotionCore

// MARK: - VoiceReciterSheet
//
// The "Voice" picker for the Muʿallim (reciter) card — choose which reciter voices the
// recitation (P). Presented in the same custom overlay as PrayerSetSheet / VoiceLanguageSheet.
// Temporary list (Reciters.all); only Muʿallim AI currently has recordings — others fall
// back to TTS until imported. Selecting writes UserPreferences.reciterId.

struct VoiceReciterSheet: View {
    let current: String        // reciterId
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void

    private var accent: Color { SettingsPalette.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Grabber
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reciter · Voice")
                        .font(Typography.eyebrow)
                        .tracking(2.5)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignTokens.faint)
                    Text("Choose the reciter")
                        .font(Typography.display(23, weight: .medium))
                        .foregroundStyle(DesignTokens.ink)
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)

            // Reciter rows — top is "Muʿallim AI Voice"
            VStack(spacing: 7) {
                ForEach(RecitationVoices.all) { reciter in
                    reciterRow(reciter)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }

    private func reciterRow(_ reciter: RecitationVoice) -> some View {
        let selected = reciter.id == current
        return Button {
            onSelect(reciter.id)
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(reciter.latinName) Voice")
                            .font(Typography.ui(15, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                        Text(reciter.arabicName)
                            .font(Typography.arabic(14))
                            .foregroundStyle(selected ? accent : DesignTokens.faint)
                    }
                    Text(reciter.style)
                        .font(Typography.ui(10))
                        .tracking(0.3)
                        .foregroundStyle(selected ? accent : DesignTokens.faint)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? accent.opacity(0.16) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? accent.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
