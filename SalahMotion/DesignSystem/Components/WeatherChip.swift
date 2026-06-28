import SwiftUI

// MARK: - WeatherChip
//
// The glanceable weather readout — icon + condition + temperature — themed by the
// caller (pass the current time-of-day theme's ink/muted/accent). Sits bottom-right,
// under the last prayer row. See docs/features/weather/SPEC.md §5.

struct WeatherChip: View {
    let state: WeatherState
    var units: TemperatureUnit = .celsius
    let ink: Color
    let muted: Color
    let accent: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: state.condition.symbolName(isDaylight: state.isDaylight))
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15))
                .foregroundStyle(accent)
            Text(state.condition.label(isDaylight: state.isDaylight))
                .font(Typography.ui(13))
                .foregroundStyle(muted)
            Text("\(state.temperatureNow(in: units))°")
                .font(Typography.ui(14, weight: .semibold))
                .foregroundStyle(ink)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
