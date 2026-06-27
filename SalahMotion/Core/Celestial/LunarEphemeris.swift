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
// illumination and waxing/waning.
//
// Position is driven by the Moon's LOCAL HOUR ANGLE (H = LST − RA), which is
// transit-relative: H = 0 IS the zenith, so the arc can't lag the way the earlier
// rise/transit/set bracketing did. dayPhase maps rise (H = −H0) → 0, transit
// (H = 0) → 0.25, set (H = +H0) → 0.5, then the night arc from set through nadir
// (H = 180°) → 0.75 back to the next rise → 1.0. H0 is the semi-diurnal arc,
// cos H0 = −tan(lat)·tan(dec).

#if canImport(SwiftAA)
import SwiftAA

struct SwiftAALunarEphemeris: CelestialEphemeris {
    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let jd = JulianDay(date)
        let moon = Moon(julianDay: jd)
        let sun = Sun(julianDay: jd)

        // Phase — apparent ecliptic longitudes at the instant.
        let elongation = moon.apparentEclipticCoordinates.celestialLongitude.value
            - sun.apparentEclipticCoordinates.celestialLongitude.value
        let phase = MoonPhase(elongationDegrees: elongation)

        // Local hour angle, degrees, normalised to (−180, 180].
        let eq = moon.apparentEquatorialCoordinates
        // SwiftAA sidereal time uses positively-WESTWARD longitude.
        let lstHours = jd.meanLocalSiderealTime(longitude: Degree(-location.longitude)).value
        var hourAngle = (lstHours - eq.rightAscension.value) * 15
        hourAngle = hourAngle.truncatingRemainder(dividingBy: 360)
        if hourAngle > 180 { hourAngle -= 360 }
        if hourAngle <= -180 { hourAngle += 360 }

        let latRad = location.latitude * .pi / 180
        let decRad = eq.declination.value * .pi / 180
        let cosH0 = max(-1, min(1, -tan(latRad) * tan(decRad)))
        let h0 = acos(cosH0) * 180 / .pi    // semi-diurnal arc, 0…180°

        let above = abs(hourAngle) <= h0
        let dayPhase: Double
        if h0 < 0.0001 {
            dayPhase = 0.75                                   // effectively never rises
        } else if above {
            dayPhase = 0.25 + 0.25 * (hourAngle / h0)         // rise 0 · transit .25 · set .5
        } else {
            let hn = hourAngle >= 0 ? hourAngle : hourAngle + 360
            let denom = 360 - 2 * h0
            dayPhase = denom > 0 ? 0.5 + 0.5 * ((hn - h0) / denom) : 0.75
        }
        return SkyState(dayPhase: dayPhase, isAboveHorizon: above, moonPhase: phase)
    }
}
#endif
