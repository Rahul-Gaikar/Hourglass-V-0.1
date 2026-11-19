import Foundation
import Testing

@testable import Hourglass

struct HourglassTests {
    @Test func testsRunInsideTheAppHost() {
        #expect(Bundle.main.bundleIdentifier == "app.hourglass.Hourglass")
    }
}
