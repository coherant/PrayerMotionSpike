import Foundation

public struct UserCalibrationProfile: Codable {
    public var rukuPitchLow:     Double
    public var rukuPitchHigh:    Double
    public var uprightPitchLow:  Double
    public var uprightPitchHigh: Double
    public var sujoodRollRadius: Double  // max angularDistance from 180°
    public var tasleemYawOffset: Double  // min yaw delta from baseline to confirm head turn

    private static let defaultsKey = "userCalibrationProfile"

    public static func load() -> UserCalibrationProfile? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let profile = try? JSONDecoder().decode(UserCalibrationProfile.self, from: data)
        else { return nil }
        return profile
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    public static func reset() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
