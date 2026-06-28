import XCTest
import WeatherKit
@testable import SalahMotion

// Stage 2 — WeatherKit → canonical condition mapping. Pure enum mapping, so it runs
// WITHOUT the WeatherKit entitlement (only the network fetch needs it).

final class WeatherConditionMappingTests: XCTestCase {

    private func mapped(_ wk: WeatherKit.WeatherCondition) -> SalahMotion.WeatherCondition {
        SalahMotion.WeatherCondition(wk)
    }

    func testCoreConditionsMap() {
        XCTAssertEqual(mapped(.clear),        .clear)
        XCTAssertEqual(mapped(.mostlyClear),  .clear)
        XCTAssertEqual(mapped(.partlyCloudy), .partlyCloudy)
        XCTAssertEqual(mapped(.mostlyCloudy), .partlyCloudy)
        XCTAssertEqual(mapped(.cloudy),       .cloudy)
        XCTAssertEqual(mapped(.foggy),        .fog)
        XCTAssertEqual(mapped(.drizzle),      .drizzle)
        XCTAssertEqual(mapped(.rain),         .rain)
        XCTAssertEqual(mapped(.heavyRain),    .heavyRain)
        XCTAssertEqual(mapped(.hail),         .hail)
    }

    func testStormVariantsCollapseToThunderstorm() {
        XCTAssertEqual(mapped(.thunderstorms),          .thunderstorm)
        XCTAssertEqual(mapped(.isolatedThunderstorms),  .thunderstorm)
        XCTAssertEqual(mapped(.scatteredThunderstorms), .thunderstorm)
        XCTAssertEqual(mapped(.strongStorms),           .thunderstorm)
    }

    func testFrozenVariantsMap() {
        XCTAssertEqual(mapped(.snow),     .snow)
        XCTAssertEqual(mapped(.heavySnow), .snow)
        XCTAssertEqual(mapped(.flurries), .snow)
        XCTAssertEqual(mapped(.blizzard), .snow)
        XCTAssertEqual(mapped(.sleet),    .sleet)
        XCTAssertEqual(mapped(.freezingRain), .sleet)
    }

    func testWindVariantsMap() {
        XCTAssertEqual(mapped(.windy),  .wind)
        XCTAssertEqual(mapped(.breezy), .wind)
    }
}
