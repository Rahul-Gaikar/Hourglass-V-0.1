import CoreMotion

/// Reads the device's gravity vector. Polled once per frame rather than pushing updates,
/// which avoids a callback per sample and any cross-thread handoff.
@MainActor
final class MotionProvider {
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates()
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    /// Latest gravity reading, or upright when motion is unavailable (e.g. in the Simulator).
    var gravity: Gravity {
        guard let gravity = manager.deviceMotion?.gravity else { return .upright }
        return Gravity(x: gravity.x, y: gravity.y)
    }
}
