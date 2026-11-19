import Foundation
import Testing

@testable import Hourglass

struct SloshModelTests {
    @Test func uprightPhoneKeepsTheSurfaceLevel() {
        #expect(Gravity.upright.surfaceAngle == 0)
    }

    @Test func tippingTheRightEdgeDownRaisesTheSurfaceOnTheRight() {
        // Rolled 30° clockwise: gravity points toward the lower right of the screen.
        let gravity = Gravity(x: sin(.pi / 6), y: -cos(.pi / 6))
        #expect(abs(gravity.surfaceAngle + .pi / 6) < 1e-9)
    }

    @Test func surfaceSettlesOnTheTargetAngle() {
        var model = SloshModel()
        for _ in 0..<600 {
            model.step(toward: 0.4, seconds: 1.0 / 60)
        }
        #expect(abs(model.angle - 0.4) < 0.001)
        #expect(model.waveAmplitude < 0.01)
    }

    @Test func surfaceOvershootsBeforeSettling() {
        var model = SloshModel()
        var peak = 0.0
        for _ in 0..<120 {
            model.step(toward: 0.4, seconds: 1.0 / 60)
            peak = max(peak, model.angle)
        }
        #expect(peak > 0.4)
    }

    @Test func angleNeverExceedsTheLimit() {
        var model = SloshModel()
        for _ in 0..<600 {
            model.step(toward: .pi, seconds: 1.0 / 60)
        }
        #expect(model.angle <= SloshModel.maxAngle)
    }

    @Test func longOrNegativeStepsAreSafe() {
        var model = SloshModel()
        model.step(toward: 0.5, seconds: -1)
        #expect(model.angle == 0)
        model.step(toward: 0.5, seconds: 3600)
        #expect(model.angle.isFinite)
        #expect(model.angle < 0.5)
    }

    @Test func settleJumpsStraightToTheTarget() {
        var model = SloshModel()
        model.step(toward: 0.5, seconds: 1.0 / 60)
        model.settle(at: -0.2)
        #expect(model.angle == -0.2)
        #expect(model.velocity == 0)
    }
}
