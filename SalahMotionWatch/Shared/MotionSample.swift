import Foundation

struct MotionSample: Identifiable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id, timestamp
        case accelerationX, accelerationY, accelerationZ
        case rotationRateX, rotationRateY, rotationRateZ
        case pitch, roll, yaw
        case pitchDegrees, rollDegrees, yawDegrees
        case detectedPosition, label
    }
    let id: UUID
    let timestamp: Date
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double
    let pitch: Double
    let roll: Double
    let yaw: Double
    let detectedPosition: PrayerPosition?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        accelerationX: Double,
        accelerationY: Double,
        accelerationZ: Double,
        rotationRateX: Double,
        rotationRateY: Double,
        rotationRateZ: Double,
        pitch: Double,
        roll: Double,
        yaw: Double,
        detectedPosition: PrayerPosition? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.rotationRateX = rotationRateX
        self.rotationRateY = rotationRateY
        self.rotationRateZ = rotationRateZ
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.detectedPosition = detectedPosition
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,            forKey: .id)
        try c.encode(timestamp,     forKey: .timestamp)
        try c.encode(accelerationX, forKey: .accelerationX)
        try c.encode(accelerationY, forKey: .accelerationY)
        try c.encode(accelerationZ, forKey: .accelerationZ)
        try c.encode(rotationRateX, forKey: .rotationRateX)
        try c.encode(rotationRateY, forKey: .rotationRateY)
        try c.encode(rotationRateZ, forKey: .rotationRateZ)
        try c.encode(pitch,         forKey: .pitch)
        try c.encode(roll,          forKey: .roll)
        try c.encode(yaw,           forKey: .yaw)
        try c.encode(pitch * 180 / .pi, forKey: .pitchDegrees)
        try c.encode(roll  * 180 / .pi, forKey: .rollDegrees)
        try c.encode(yaw   * 180 / .pi, forKey: .yawDegrees)
        try c.encodeIfPresent(detectedPosition,         forKey: .detectedPosition)
        try c.encodeIfPresent(detectedPosition?.rawValue, forKey: .label)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        timestamp        = try c.decode(Date.self,   forKey: .timestamp)
        accelerationX    = try c.decode(Double.self, forKey: .accelerationX)
        accelerationY    = try c.decode(Double.self, forKey: .accelerationY)
        accelerationZ    = try c.decode(Double.self, forKey: .accelerationZ)
        rotationRateX    = try c.decode(Double.self, forKey: .rotationRateX)
        rotationRateY    = try c.decode(Double.self, forKey: .rotationRateY)
        rotationRateZ    = try c.decode(Double.self, forKey: .rotationRateZ)
        pitch            = try c.decode(Double.self, forKey: .pitch)
        roll             = try c.decode(Double.self, forKey: .roll)
        yaw              = try c.decode(Double.self, forKey: .yaw)
        detectedPosition = try c.decodeIfPresent(PrayerPosition.self, forKey: .detectedPosition)
    }

    func labeled(as position: PrayerPosition) -> MotionSample {
        MotionSample(
            id: id,
            timestamp: timestamp,
            accelerationX: accelerationX,
            accelerationY: accelerationY,
            accelerationZ: accelerationZ,
            rotationRateX: rotationRateX,
            rotationRateY: rotationRateY,
            rotationRateZ: rotationRateZ,
            pitch: pitch,
            roll: roll,
            yaw: yaw,
            detectedPosition: position
        )
    }
}
