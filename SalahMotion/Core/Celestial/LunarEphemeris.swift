import Foundation

// MARK: - Lunar ephemeris resolution
//
// `Lunar.ephemeris` is the single place the rest of the app asks for "the Moon".
// It resolves to the real SwiftAA-backed provider once that package is vendored,
// and otherwise to a deliberately-obvious placeholder.

enum Lunar {
    static var ephemeris: CelestialEphemeris {
        #if canImport(SwiftAA)
        return SwiftAALunarEphemeris()
        #else
        // PLACEHOLDER until SwiftAA is vendored. Deliberately the Sun's antipode,
        // so a missing dependency fails VISIBLY (a moon forever opposite the sun)
        // rather than shipping a subtly-wrong, drifting position. Never production.
        return OpposedEphemeris(base: SolarEphemeris())
        #endif
    }
}

// MARK: - SwiftAALunarEphemeris (real, SwiftAA 3.x)
//
// Phase = elongation (Moon − Sun apparent ecliptic longitude), which encodes both
// illumination and waxing/waning. Position reuses the shared `DailyArc` mapping,
// fed by SwiftAA's moonrise / transit / moonset for the observer's day.
//
// Known rough edge: the Moon's rise/set don't always fall in tidy rise<transit<set
// order within one UT day (its day is ~24h50m), so on awkward days the arc
// position can be approximate. The phase (the visible face) is always correct.
// A future refinement could drive position from hour-angle/altitude directly.

#if canImport(SwiftAA)
import SwiftAA

struct SwiftAALunarEphemeris: CelestialEphemeris {
    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        // SwiftAA uses positively-WESTWARD longitude, so east longitude is negated.
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.longitude),
            latitude: Degree(location.latitude)
        )

        // Phase — apparent ecliptic longitudes at the instant.
        let moon = Moon(julianDay: JulianDay(date))
        let sun = Sun(julianDay: JulianDay(date))
        let elongation = moon.apparentEclipticCoordinates.celestialLongitude.value
            - sun.apparentEclipticCoordinates.celestialLongitude.value
        let phase = MoonPhase(elongationDegrees: elongation)

        // Position — moonrise / transit / set for the day, through DailyArc.
        let today = riseTransitSet(for: date, geo: geo)
        guard let rise = today.riseTime?.date,
              let transit = today.transitTime?.date,
              let set = today.setTime?.date else {
            // No clean rise/transit/set this day → treat as below the horizon.
            return SkyState(dayPhase: 0.75, isAboveHorizon: false, moonPhase: phase)
        }
        let previousSet = riseTransitSet(for: date.addingTimeInterval(-86_400), geo: geo).setTime?.date
        let nextRise = riseTransitSet(for: date.addingTimeInterval(86_400), geo: geo).riseTime?.date

        let dayPhase = DailyArc.phase(now: date, previousSet: previousSet,
                                      rise: rise, transit: transit, set: set,
                                      nextRise: nextRise)
        let above = date >= rise && date < set
        return SkyState(dayPhase: dayPhase, isAboveHorizon: above, moonPhase: phase)
    }

    private func riseTransitSet(for date: Date, geo: GeographicCoordinates) -> RiseTransitSetTimes {
        RiseTransitSetTimes(celestialBody: Moon(julianDay: JulianDay(date)),
                            geographicCoordinates: geo)
    }
}
#endif
