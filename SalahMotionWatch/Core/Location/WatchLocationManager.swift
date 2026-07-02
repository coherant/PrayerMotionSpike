import CoreLocation

// Watch CoreLocation wrapper (mirrors the iPhone's LocationManager). One instance; requests
// a single fix, reverse-geocodes the city name + timezone, and feeds WatchPrayerTimes so the
// on-wrist times reflect where you actually are. Falls back to the Melbourne default on denial.
@Observable
final class WatchLocationManager: NSObject {
    static let shared = WatchLocationManager()

    private(set) var cityName: String = "Locating…"
    private(set) var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var hasFetched = false
    private var lastGeocoded: CLLocation?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        guard !hasFetched else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            fetchOnce()
        case .denied, .restricted:
            cityName = "Location off"
        @unknown default:
            break
        }
    }

    private func fetchOnce() {
        guard !hasFetched else { return }
        hasFetched = true
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        // Only geocode a genuinely new spot — respects CLGeocoder's throttle.
        if let last = lastGeocoded, location.distance(from: last) < 500 { return }
        lastGeocoded = location
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let placemark = placemarks?.first
            let city = placemark?.locality ?? placemark?.administrativeArea ?? "Unknown"
            let tz = placemark?.timeZone
            DispatchQueue.main.async {
                self?.cityName = city
                if let tz { WatchPrayerTimes.shared.setTimeZone(tz) }
            }
        }
    }
}

extension WatchLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            fetchOnce()
        case .denied, .restricted:
            cityName = "Location off"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.coordinate = location.coordinate
            WatchPrayerTimes.shared.setCoordinate(location.coordinate)
        }
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if cityName == "Locating…" { cityName = "Melbourne" }
    }
}
