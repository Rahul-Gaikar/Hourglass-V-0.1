import Foundation
import Testing

@testable import Hourglass

struct SessionAlertTests {
    private let settings = PomodoroSettings()

    @Test func endOfFocusInvitesAShortBreak() {
        let alert = SessionAlert(finishing: .focus, next: .shortBreak, settings: settings)
        #expect(alert.title == "Focus complete")
        #expect(alert.body == "Time for a 5-minute break. Flip your hourglass to start it.")
    }

    @Test func endOfFocusCanEarnALongBreak() {
        let alert = SessionAlert(finishing: .focus, next: .longBreak, settings: settings)
        #expect(alert.body == "Time for a 15-minute long break. Flip your hourglass to start it.")
    }

    @Test(arguments: [SessionPhase.shortBreak, .longBreak])
    func endOfABreakInvitesFocus(phase: SessionPhase) {
        let alert = SessionAlert(finishing: phase, next: .focus, settings: settings)
        #expect(alert.title == "Break's over")
        #expect(alert.body == "Flip your hourglass when you're ready to focus.")
    }
}
