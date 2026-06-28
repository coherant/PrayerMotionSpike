import SwiftUI

// MARK: - ScreenHeader
//
// The standardized title/eyebrow container shared by every screen that has a
// header (PrayerTimes, Settings, Calibration, PrayerSetup). Keeps the eyebrow +
// title typography, the 22pt gutter, and the top/bottom spacing identical across
// the app so headers don't jump when switching tabs.
//
// Optional `leading` (e.g. a back button) and `trailing` (e.g. a location pill)
// slots; omit either via the convenience initializers below.

struct ScreenHeader<Leading: View, Trailing: View>: View {
    let eyebrow: String
    let title: String
    let accent: Color
    let ink: Color
    let leading: Leading
    let trailing: Trailing

    init(
        eyebrow: String,
        title: String,
        accent: Color,
        ink: Color = DesignTokens.ink,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.accent = accent
        self.ink = ink
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            leading

            VStack(alignment: .leading, spacing: 1) {
                Text(eyebrow)
                    .font(.system(size: 10.5, weight: .semibold))
                    // Tightened 2.5 → 2.0 to buy horizontal room so the longest
                    // eyebrow ("… · AFTERNOON") fits on one line at full size,
                    // without scaling the date down (see lineLimit note below).
                    .tracking(2.0)
                    .textCase(.uppercase)
                    .foregroundStyle(accent)
                    .lineLimit(1)                 // never wrap (e.g. "· AFTERNOON")
                    // No minimumScaleFactor: scaling-to-fit couples the font size to
                    // the eyebrow's length, so the leading date PULSED in size as the
                    // trailing "· PHASE" word changed length during the celestial
                    // animation/egg. Hold the date at full size; the trailing phase
                    // label tail-truncates instead.
                Text(title)
                    .font(Typography.display(26, weight: .medium))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            trailing
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Convenience inits (omit leading and/or trailing)

extension ScreenHeader where Trailing == EmptyView {
    init(
        eyebrow: String,
        title: String,
        accent: Color,
        ink: Color = DesignTokens.ink,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(eyebrow: eyebrow, title: title, accent: accent, ink: ink,
                  leading: leading, trailing: { EmptyView() })
    }
}

extension ScreenHeader where Leading == EmptyView {
    init(
        eyebrow: String,
        title: String,
        accent: Color,
        ink: Color = DesignTokens.ink,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(eyebrow: eyebrow, title: title, accent: accent, ink: ink,
                  leading: { EmptyView() }, trailing: trailing)
    }
}

extension ScreenHeader where Leading == EmptyView, Trailing == EmptyView {
    init(
        eyebrow: String,
        title: String,
        accent: Color,
        ink: Color = DesignTokens.ink
    ) {
        self.init(eyebrow: eyebrow, title: title, accent: accent, ink: ink,
                  leading: { EmptyView() }, trailing: { EmptyView() })
    }
}
