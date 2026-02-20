import CoreMotion
import Combine

class MotionService: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var accelX: Double = 0
    @Published var accelY: Double = 0
    @Published var accelZ: Double = 0
    @Published var isReceivingData = false
    @Published var sampleCount: Int = 0
    @Published var isAvailable: Bool = true

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }

        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion, let self else { return }
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
            self.accelX = motion.userAcceleration.x
            self.accelY = motion.userAcceleration.y
            self.accelZ = motion.userAcceleration.z
            self.sampleCount += 1
            if self.sampleCount >= 30 {
                self.isReceivingData = true
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
