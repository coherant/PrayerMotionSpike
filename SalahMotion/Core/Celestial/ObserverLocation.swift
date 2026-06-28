import Foundation

// MARK: - ObserverLocation
//
// A lightweight observer position for the celestial domain. Deliberately NOT the
// Adhan `Coordinates` type — keeping the domain's public surface free of the
// vendored library means providers can be swapped and tested in isolation, and
// the model ports to watchOS without dragging prayer-time types along.

struct ObserverLocation: Equatable {
    let latitude: Double
    let longitude: Double

    /// The observer's civil timezone — used only to decide which calendar DAY a
    /// moment belongs to when bracketing the Sun's rise/transit/set. It MUST be the
    /// location's tz, not the device's: the Adhan solar algorithm anchors events to
    /// a calendar day, and at large UTC offsets (e.g. Melbourne UTC+10) the *UTC*
    /// day boundary falls mid-morning, so bracketing by the UTC day makes the solar
    /// dayPhase jump to the horizon there. Defaults to UTC (correct near longitude
    /// 0, and the safe assumption for tests).
    var timeZone: TimeZone = .gregorianUTCZone

    /// Drives the Moon's bright-limb mirroring: in the Southern Hemisphere the
    /// lit side is flipped relative to the Northern convention. The *view* applies
    /// the mirror; the domain just reports which hemisphere we're in.
    var isNorthernHemisphere: Bool { latitude >= 0 }
}

extension TimeZone {
    /// UTC, force-unwrapped once (the identifier always resolves). A small named
    /// constant so `ObserverLocation`'s default is readable.
    static let gregorianUTCZone = TimeZone(identifier: "UTC")!
}
