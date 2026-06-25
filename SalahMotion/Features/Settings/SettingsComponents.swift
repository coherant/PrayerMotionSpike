import SwiftUI

// MARK: - Settings theme + reusable components
// Source: docs/features/settings/settings.html
//
// The Settings flow uses a fixed dark palette with the accent driven by the
// current prayer (matching the rest of the app). Per-prayer rows use that
// prayer's own accent (PrayerTime.theme.accent), which lines up exactly with
// the mockup's hex values.

enum SettingsPalette {
    static let ink   = Color(hex: "#f4f1fa")
    static let muted = Color(hex: "#b8b2c8")
    static let faint = Color(hex: "#847e98")

    /// Accent for global chrome (header, main cards, language, rate…).
    static var accent: Color { PrayerTime.current.theme.accent }

    static let background = LinearGradient(
        stops: [
            .init(color: Color(hex: "#1a1730"), location: 0.0),
            .init(color: Color(hex: "#131120"), location: 0.6),
            .init(color: Color(hex: "#100e1b"), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let hairline = Color.white.opacity(0.07)
    static let cardFill = Color.white.opacity(0.035)
}

// MARK: - Section label (eyebrow)

struct SettingsSectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Typography.ui(11, weight: .semibold))
            .tracking(2.5)
            .textCase(.uppercase)
            .foregroundStyle(SettingsPalette.faint)
    }
}

// MARK: - Card background

struct SettingsCard: ViewModifier {
    var cornerRadius: CGFloat = 14
    var fill: Color = SettingsPalette.cardFill
    var border: Color = SettingsPalette.hairline

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
    }
}

extension View {
    func settingsCard(cornerRadius: CGFloat = 14,
                      fill: Color = SettingsPalette.cardFill,
                      border: Color = SettingsPalette.hairline) -> some View {
        modifier(SettingsCard(cornerRadius: cornerRadius, fill: fill, border: border))
    }
}

// MARK: - Chevron

struct SettingsChevron: View {
    var color: Color = SettingsPalette.muted
    var rotated: Bool = false
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotated ? 90 : 0))
    }
}

// MARK: - Pill toggle

struct SettingsToggle: View {
    @Binding var isOn: Bool
    var accent: Color

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? accent : Color.white.opacity(0.15))
                .frame(width: 44, height: 26)
            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .padding(3)
        }
        .frame(width: 44, height: 26)
        .contentShape(Capsule())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.18)) { isOn.toggle() }
        }
    }
}

// MARK: - Ring radio

struct SettingsRadio: View {
    let selected: Bool
    var accent: Color
    var body: some View {
        Circle()
            .strokeBorder(selected ? accent : Color.white.opacity(0.22),
                          lineWidth: selected ? 6 : 1.5)
            .frame(width: 20, height: 20)
    }
}

// MARK: - Circular stepper

struct SettingsStepper: View {
    let display: String
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            button(system: "minus", action: onMinus)
            Text(display)
                .font(Typography.ui(13, weight: .semibold))
                .foregroundStyle(SettingsPalette.ink)
                .monospacedDigit()
                .frame(minWidth: 52)
            button(system: "plus", action: onPlus)
        }
    }

    private func button(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SettingsPalette.muted)
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Radio option row (for expandable method / reciter lists)

struct SettingsOptionRow: View {
    let label: String
    var arabic: String? = nil
    var detail: String? = nil
    let selected: Bool
    var accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                SettingsRadio(selected: selected, accent: accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(Typography.ui(13.5, weight: .semibold))
                        .foregroundStyle(selected ? SettingsPalette.ink : SettingsPalette.muted)
                    if let detail {
                        Text(detail)
                            .font(Typography.ui(11))
                            .foregroundStyle(SettingsPalette.faint)
                    }
                }
                Spacer(minLength: 0)
                if let arabic {
                    Text(arabic)
                        .font(Typography.arabic(12))
                        .environment(\.layoutDirection, .rightToLeft)
                        .foregroundStyle(SettingsPalette.faint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .settingsCard(
                cornerRadius: 11,
                fill: selected ? accent.opacity(0.12) : Color.white.opacity(0.025),
                border: selected ? accent.opacity(0.32) : Color.white.opacity(0.06)
            )
        }
        .buttonStyle(.plain)
    }
}
