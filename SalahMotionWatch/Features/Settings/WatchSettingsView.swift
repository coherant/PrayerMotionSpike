import SwiftUI

// Watch Settings — native watchOS styling (plain List; theming comes later). Only the
// items that fit the wrist: calculation method, madhab, fajr rule (feed WatchPrayerTimes),
// and per-prayer + suhoor alert toggles. Set-once phone config (offsets, hijri, angle
// sub-methods, reciter) is intentionally left off — to be sync-only from the phone.
struct WatchSettingsView: View {
    @Bindable private var settings = WatchPrayerSettings.shared

    private let alertPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    var body: some View {
        List {
            Section("Calculation") {
                NavigationLink {
                    MethodPicker()
                } label: {
                    valueRow("Method", settings.method.watchName)
                }
                NavigationLink {
                    MadhabPicker()
                } label: {
                    valueRow("Madhab", WatchSettingsView.madhabName(settings.madhab))
                }
                NavigationLink {
                    FajrRulePicker()
                } label: {
                    valueRow("Fajr", settings.fajrRule.name)
                }
            }

            Section("Alerts") {
                ForEach(alertPrayers, id: \.self) { prayer in
                    Toggle(WatchSettingsView.prayerName(prayer), isOn: Binding(
                        get: { settings.isAlertEnabled(prayer) },
                        set: { settings.setAlert(prayer, $0) }
                    ))
                }
                Toggle("Suhoor reminder", isOn: $settings.suhoorReminder)
            }
        }
        .navigationTitle("Settings")
    }

    private func valueRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).font(.footnote)
        }
    }

    static func madhabName(_ m: Madhab) -> String { m == .shafi ? "Shafiʿi" : "Hanafi" }

    static func prayerName(_ p: Prayer) -> String {
        switch p {
        case .fajr:    "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr:   "Dhuhr"
        case .asr:     "Asr"
        case .maghrib: "Maghrib"
        case .isha:    "Isha"
        }
    }
}

// MARK: - Sub-pickers (native selection lists)

private struct MethodPicker: View {
    @Bindable private var settings = WatchPrayerSettings.shared
    var body: some View {
        List(CalculationMethod.allCases, id: \.self) { method in
            Button { settings.method = method } label: {
                HStack {
                    Text(method.watchName).foregroundStyle(.primary)
                    Spacer()
                    if settings.method == method { Image(systemName: "checkmark").foregroundStyle(.tint) }
                }
            }
        }
        .navigationTitle("Method")
    }
}

private struct MadhabPicker: View {
    @Bindable private var settings = WatchPrayerSettings.shared
    var body: some View {
        List(Madhab.allCases, id: \.self) { madhab in
            Button { settings.madhab = madhab } label: {
                HStack {
                    Text(WatchSettingsView.madhabName(madhab)).foregroundStyle(.primary)
                    Spacer()
                    if settings.madhab == madhab { Image(systemName: "checkmark").foregroundStyle(.tint) }
                }
            }
        }
        .navigationTitle("Madhab")
    }
}

private struct FajrRulePicker: View {
    @Bindable private var settings = WatchPrayerSettings.shared
    var body: some View {
        List(WatchFajrRule.allCases) { rule in
            Button { settings.fajrRule = rule } label: {
                HStack {
                    Text(rule.name).foregroundStyle(.primary)
                    Spacer()
                    if settings.fajrRule == rule { Image(systemName: "checkmark").foregroundStyle(.tint) }
                }
            }
        }
        .navigationTitle("Fajr Rule")
    }
}
