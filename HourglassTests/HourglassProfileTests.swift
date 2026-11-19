import Foundation
import Testing

@testable import Hourglass

struct HourglassProfileTests {
    private let profile = HourglassProfile()

    @Test func glassIsNarrowAtTheNeckAndWidestAtTheEnds() {
        #expect(profile.halfWidth(at: 0) == profile.neckHalfWidth)
        #expect(abs(profile.halfWidth(at: 1) - 1) < 1e-9)
        #expect(profile.halfWidth(at: 0.25) < profile.halfWidth(at: 0.75))
    }

    @Test func topBulbStartsPartlyFullAndEndsEmpty() {
        let fullLevel = profile.topLevel(progress: 0)
        #expect(fullLevel > 0.3)
        #expect(fullLevel < 1)
        #expect(profile.topLevel(progress: 1) == 0)
    }

    @Test func bottomBulbStartsEmptyAndFillsTowardTheNeck() {
        #expect(profile.bottomLevel(progress: 0) == 1)
        #expect(profile.bottomLevel(progress: 1) < profile.bottomLevel(progress: 0.5))
        #expect(profile.bottomLevel(progress: 1) > 0)
    }

    @Test(arguments: [0.0, 0.1, 0.33, 0.5, 0.9, 1.0])
    func liquidIsConservedAsItDrains(progress: Double) {
        let inTop = profile.area(upTo: profile.topLevel(progress: progress))
        let inBottom = profile.bulbArea - profile.area(upTo: profile.bottomLevel(progress: progress))
        #expect(abs(inTop + inBottom - profile.liquidArea) < profile.liquidArea * 0.001)
    }

    @Test func progressOutsideZeroToOneIsClamped() {
        #expect(profile.topLevel(progress: -1) == profile.topLevel(progress: 0))
        #expect(profile.bottomLevel(progress: 2) == profile.bottomLevel(progress: 1))
    }
}
