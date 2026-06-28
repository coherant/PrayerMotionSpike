import XCTest
import CoreLocation
@testable import SalahMotion

// Stage 1 — core weather domain + cache. Pure logic, no UI, no network, no entitlement.
// (Provider→condition mapping is tested in Stage 2 with WeatherKitProvider.)

final class WeatherTests: XCTestCase {

    private let melbourne = CLLocation(latitude: -37.8136, longitude: 144.9631)
    private let sydney    = CLLocation(latitude: -33.8688, longitude: 151.2093)

    // MARK: Cache hit / miss

    func testSecondIdenticalRequestHitsCache() async throws {
        let spy = SpyProvider(.sample(.rain))
        let sut = CachedWeatherProvider(upstream: spy, cache: WeatherCache(fileURL: nil))
        let now = Date()

        let first  = try await sut.weather(for: melbourne, on: now)
        let second = try await sut.weather(for: melbourne, on: now)

        let calls = await spy.count
        XCTAssertEqual(calls, 1, "the second identical request should be served from cache")
        XCTAssertEqual(first, second)
    }

    func testNewTimeWindowRefetches() async throws {
        let spy = SpyProvider(.sample(.clear))
        let window: TimeInterval = 6 * 3600
        let sut = CachedWeatherProvider(upstream: spy, cache: WeatherCache(fileURL: nil), window: window)
        let t0 = Date(timeIntervalSince1970: 1_000_000)

        _ = try await sut.weather(for: melbourne, on: t0)
        _ = try await sut.weather(for: melbourne, on: t0.addingTimeInterval(window + 1)) // next bucket

        let calls = await spy.count
        XCTAssertEqual(calls, 2, "crossing into a new time window should refetch")
    }

    func testNearbyCoordsShareGridCell() async throws {
        let spy = SpyProvider(.sample(.cloudy))
        let sut = CachedWeatherProvider(upstream: spy, cache: WeatherCache(fileURL: nil))
        let now = Date()
        let nearby = CLLocation(latitude: melbourne.coordinate.latitude + 0.01,
                                longitude: melbourne.coordinate.longitude + 0.01) // within one ~10km cell

        _ = try await sut.weather(for: melbourne, on: now)
        _ = try await sut.weather(for: nearby, on: now)

        let calls = await spy.count
        XCTAssertEqual(calls, 1, "coords within the same grid cell should share a cache entry")
    }

    func testDistantCoordsRefetch() async throws {
        let spy = SpyProvider(.sample(.cloudy))
        let sut = CachedWeatherProvider(upstream: spy, cache: WeatherCache(fileURL: nil))
        let now = Date()

        _ = try await sut.weather(for: melbourne, on: now)
        _ = try await sut.weather(for: sydney, on: now)

        let calls = await spy.count
        XCTAssertEqual(calls, 2, "a different grid cell should refetch")
    }

    // MARK: WeatherState

    func testCodableRoundTrip() throws {
        let original = WeatherState.sample(.thunderstorm)
        let decoded = try JSONDecoder().decode(
            WeatherState.self,
            from: try JSONEncoder().encode(original)
        )
        XCTAssertEqual(original, decoded)
    }

    func testTemperatureConversion() {
        let s = WeatherState.sample(.clear)   // tempNowC = 18
        XCTAssertEqual(s.temperatureNow(in: .celsius), 18)
        XCTAssertEqual(s.temperatureNow(in: .fahrenheit), 64)  // 18°C = 64.4°F → 64
    }
}

// MARK: - Test double

/// Counts upstream calls so we can assert cache hits vs misses. An actor for
/// safe mutation across the provider's `async` boundary.
private actor SpyProvider: WeatherProvider {
    private(set) var count = 0
    private let state: WeatherState

    init(_ state: WeatherState) { self.state = state }

    func weather(for location: CLLocation, on date: Date) async throws -> WeatherState {
        count += 1
        return state
    }
}
