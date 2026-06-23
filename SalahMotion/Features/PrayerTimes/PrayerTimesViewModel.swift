import Foundation

// TODO: Implement prayer times view model

@Observable
final class PrayerTimesViewModel {

    var hijriDate: String {
        var cal = Calendar(identifier: .islamicCivil)
        cal.locale = Locale(identifier: "en")
        let c = cal.dateComponents([.day, .month, .year], from: Date())
        guard let day = c.day, let month = c.month, let year = c.year,
              (1...12).contains(month) else { return "" }
        let months = ["Muḥarram","Ṣafar","Rabīʿ al-Awwal","Rabīʿ al-Thānī",
                      "Jumādā al-Ūlā","Jumādā al-Ākhirah","Rajab","Shaʿbān",
                      "Ramaḍān","Shawwāl","Dhū al-Qaʿdah","Dhū al-Ḥijjah"]
        return "\(day) \(months[month - 1]) \(year)"
    }
}
