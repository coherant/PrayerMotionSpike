import Foundation

public struct SensorReadings {
    private var pitches: [Double] = []
    private var rolls:   [Double] = []
    private var yaws:    [Double] = []
    private let windowSize: Int

    public init(windowSize: Int = 7) { self.windowSize = windowSize }

    public mutating func add(pitch: Double, roll: Double, yaw: Double) {
        pitches = Array((pitches + [pitch]).suffix(windowSize))
        rolls   = Array((rolls   + [roll]).suffix(windowSize))
        yaws    = Array((yaws    + [yaw]).suffix(windowSize))
    }

    public var smoothedPitch: Double { pitches.isEmpty ? 0 : pitches.reduce(0, +) / Double(pitches.count) }
    public var smoothedRoll:  Double { rolls.isEmpty   ? 0 : rolls.reduce(0, +)   / Double(rolls.count) }
    public var smoothedYaw:   Double { yaws.isEmpty    ? 0 : yaws.reduce(0, +)    / Double(yaws.count) }
}
