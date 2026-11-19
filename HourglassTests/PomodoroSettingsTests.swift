import Foundation
import Testing

@testable import Hourglass

struct PomodoroSettingsTests {
    @Test func defaultsAreTheClassicPomodoro() {
        let settings = PomodoroSettings()
        #expect(settings.duration(for: .focus) == 25 * 60)
        #expect(settings.duration(for: .shortBreak) == 5 * 60)
        #expect(settings.duration(for: .longBreak) == 15 * 60)
        #expect(settings.effectiveSessionsBeforeLongBreak == 4)
    }

    @Test(arguments: [(-5, 60.0), (0, 60.0), (30, 1800.0), (120, 7200.0), (500, 7200.0)])
    func durationsAreClampedToTheAllowedRange(minutes: Int, expectedSeconds: Double) {
        let settings = PomodoroSettings(focusMinutes: minutes)
        #expect(settings.duration(for: .focus) == expectedSeconds)
    }

    @Test(arguments: [(0, 1), (4, 4), (99, 12)])
    func sessionsBeforeLongBreakIsClamped(value: Int, expected: Int) {
        let settings = PomodoroSettings(sessionsBeforeLongBreak: value)
        #expect(settings.effectiveSessionsBeforeLongBreak == expected)
    }
}
