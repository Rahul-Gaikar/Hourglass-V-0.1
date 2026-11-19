import Foundation
import Testing

@testable import Hourglass

struct TimeLabelTests {
    @Test(arguments: [
        (1500.0, "25:00"),
        (1499.2, "25:00"),
        (61.0, "1:01"),
        (9.0, "0:09"),
        (0.1, "0:01"),
        (0.0, "0:00"),
        (-5.0, "0:00"),
        (7200.0, "120:00"),
    ])
    func formatsRemainingTimeRoundingUp(remaining: Double, expected: String) {
        #expect(TimeLabel.text(for: remaining) == expected)
    }
}
