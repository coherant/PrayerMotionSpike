import Foundation
import CoreMotion

@Observable
final class MotionManager {
    private let cm = CMMotionManager()

    var pitch: Double = 0
    var roll: Double = 0
    var yaw: Double = 0
    var accelerationX: Double = 0
    var accelerationY: Double = 0
    var accelerationZ: Double = 0
    var rotationRateX: Double = 0
    var rotationRateY: Double = 0
    var rotationRateZ: Double = 0
    var isActive = false
    private(set) var latestSample: MotionSample?

    func start() {
        guard cm.isDeviceMotionAvailable, !isActive else { return }
        cm.deviceMotionUpdateInterval = 1.0 / 50.0
        // Use main queue so @Observable property updates are always on the main actor
        cm.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            let attitude = motion.attitude
            let acc = motion.userAcceleration
            let rot = motion.rotationRate

            self.pitch = attitude.pitch
            self.roll = attitude.roll
            self.yaw = attitude.yaw
            self.accelerationX = acc.x
            self.accelerationY = acc.y
            self.accelerationZ = acc.z
            self.rotationRateX = rot.x
            self.rotationRateY = rot.y
            self.rotationRateZ = rot.z
            self.isActive = true
            self.latestSample = MotionSample(
                accelerationX: acc.x,
                accelerationY: acc.y,
                accelerationZ: acc.z,
                rotationRateX: rot.x,
                rotationRateY: rot.y,
                rotationRateZ: rot.z,
                pitch: attitude.pitch,
                roll: attitude.roll,
                yaw: attitude.yaw,
                detectedPosition: PrayerPosition.classify(pitch: attitude.pitch, roll: attitude.roll)
            )
        }
    }

    func stop() {
        cm.stopDeviceMotionUpdates()
        isActive = false
    }
}
