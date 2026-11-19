import Foundation

/// Gravity in device coordinates (x toward the right edge, y toward the top edge), in g.
struct Gravity: Equatable, Sendable {
    static let upright = Gravity(x: 0, y: -1)

    var x: Double
    var y: Double

    /// The same gravity seen from a frame turned 180° (when the hourglass is drawn upside down).
    var turnedOver: Gravity {
        Gravity(x: -x, y: -y)
    }

    /// Angle of a level liquid surface in screen space, in radians.
    /// 0 when the phone is upright; negative when the right edge is tipped down (the surface rises on the right).
    var surfaceAngle: Double {
        -atan2(x, -y)
    }
}

/// Damped spring for the liquid surface, so it lags behind the device's tilt and wobbles as it settles.
struct SloshModel: Sendable {
    /// The surface never tilts past this, which also keeps an upside-down phone from spinning the liquid.
    static let maxAngle = Double.pi / 3

    var stiffness = 55.0
    var damping = 6.5
    private(set) var angle = 0.0
    private(set) var velocity = 0.0

    /// Advances the simulation by `seconds` toward the surface angle `target`.
    mutating func step(toward target: Double, seconds: Double) {
        // Cap the step so a dropped frame or a return from the background can't make the spring explode.
        let dt = seconds.clamped(to: 0...(1.0 / 30))
        guard dt > 0 else { return }
        let goal = target.clamped(to: -Self.maxAngle...Self.maxAngle)
        let acceleration = -stiffness * (angle - goal) - damping * velocity
        velocity += acceleration * dt
        angle = (angle + velocity * dt).clamped(to: -Self.maxAngle...Self.maxAngle)
    }

    /// Jumps straight to `target` with no motion (used when Reduce Motion is on).
    mutating func settle(at target: Double) {
        angle = target.clamped(to: -Self.maxAngle...Self.maxAngle)
        velocity = 0
    }

    /// How rough the surface is, from 0 (still) to 1, driven by how fast the liquid is moving.
    var waveAmplitude: Double {
        min(1, abs(velocity) / 2.5)
    }
}
