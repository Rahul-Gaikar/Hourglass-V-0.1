import Foundation
import Testing

@testable import Hourglass

struct FlipDetectorTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let upsideDown = Gravity(x: 0, y: 0.95)

    /// Feeds `gravity` every 50 ms for `seconds` and returns how many flips were reported.
    private func flips(
        _ detector: inout FlipDetector,
        gravity: Gravity,
        seconds: Double,
        from time: inout Date
    ) -> Int {
        var count = 0
        for _ in 0..<Int(seconds / 0.05) {
            if detector.update(gravity: gravity, at: time) {
                count += 1
            }
            time = time.addingTimeInterval(0.05)
        }
        return count
    }

    @Test func uprightOrFlatPhoneNeverFlips() {
        var detector = FlipDetector()
        var time = start
        #expect(flips(&detector, gravity: .upright, seconds: 5, from: &time) == 0)
        #expect(flips(&detector, gravity: Gravity(x: 0, y: 0), seconds: 5, from: &time) == 0)
    }

    @Test func holdingUpsideDownFlipsOnce() {
        var detector = FlipDetector()
        var time = start
        #expect(flips(&detector, gravity: upsideDown, seconds: 3, from: &time) == 1)
    }

    @Test func briefInversionIsIgnored() {
        var detector = FlipDetector()
        var time = start
        #expect(flips(&detector, gravity: upsideDown, seconds: 0.2, from: &time) == 0)
        #expect(flips(&detector, gravity: .upright, seconds: 0.2, from: &time) == 0)
        #expect(flips(&detector, gravity: upsideDown, seconds: 0.2, from: &time) == 0)
    }

    @Test func turningBackUprightReArmsTheDetector() {
        var detector = FlipDetector()
        var time = start
        #expect(flips(&detector, gravity: upsideDown, seconds: 1, from: &time) == 1)
        #expect(flips(&detector, gravity: .upright, seconds: 0.5, from: &time) == 0)
        #expect(flips(&detector, gravity: upsideDown, seconds: 1, from: &time) == 1)
    }

    @Test func sidewaysTiltIsNotAFlip() {
        var detector = FlipDetector()
        var time = start
        let onItsSide = Gravity(x: 0.9, y: 0.3)
        #expect(flips(&detector, gravity: onItsSide, seconds: 2, from: &time) == 0)
    }
}
