import SwiftUI

// MARK: - VoiceLanguageSheet
//
// The "Change language" sheet for a single voice (Murshid → guidance, Muʿallim →
// recitation). Presented in the same custom overlay as PrayerSetSheet (blur + dim +
// spring) from PrayerSetupView. Picking a row writes the voice's language and the
// pill on the card updates. Muezzin is Arabic-only, so it has no sheet.

struct VoiceLanguageSheet: View {
    let title: String          // "Murshid" / "Muʿallim"
    let arabic: String         // "مرشد" / "معلّم"
    let current: Language
    @Binding var isPresented: Bool
    let onSelect: (Language) -> Void

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
                    HStack(spacing: 6) {
                        Text("\(title) · Language")
                            .font(Typography.eyebrow)
                            .tracking(2.5)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignTokens.faint)
                        Text(arabic)
                            .font(Typography.arabic(13))
                            .foregroundStyle(accent)
                    }
                    Text("Choose the voice language")
                        .font(Typography.display(23, weight: .medium))
                        .foregroundStyle(DesignTokens.ink)
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)

            // Language rows (same labels as the old recitation/guidance buttons)
            VStack(spacing: 7) {
                ForEach(Language.allCases) { lang in
                    languageRow(lang)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
    }

    private func languageRow(_ lang: Language) -> some View {
        let selected = lang == current
        return Button {
            onSelect(lang)
            isPresented = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if lang == .arabic {
                        Text("العربية").font(Typography.arabic(18)).foregroundStyle(DesignTokens.ink)
                    } else {
                        Text(lang.displayName).font(Typography.ui(15, weight: .semibold)).foregroundStyle(DesignTokens.ink)
                    }
                    Text(lang == .arabic ? "Arabic" : lang == .turkish ? "Turkish" : "Latin")
                        .font(Typography.ui(10))
                        .tracking(0.4)
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
