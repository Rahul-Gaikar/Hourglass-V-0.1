import Foundation
import Testing

@testable import Hourglass

struct LiveActivityStateTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func idleTimerShowsNoActivity() {
        #expect(HourglassActivityAttributes.ContentState(timer: PomodoroTimer(), now: start) == nil)
    }

    @Test func runningTimerCountsDownFromItsStart() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        let state = HourglassActivityAttributes.ContentState(timer: timer, now: start.addingTimeInterval(60))
        #expect(state?.startDate == start)
        #expect(state?.endDate == start.addingTimeInterval(25 * 60))
        #expect(state?.phaseDuration == TimeInterval(25 * 60))
        #expect(state?.isPaused == false)
    }

    @Test func pausedTimerFreezesTheRemainingTime() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        timer.pause(at: start.addingTimeInterval(10 * 60))
        let later = start.addingTimeInterval(60 * 60)
        let state = HourglassActivityAttributes.ContentState(timer: timer, now: later)
        #expect(state?.pausedRemaining == TimeInterval(15 * 60))
        #expect(state?.endDate == later.addingTimeInterval(15 * 60))
    }

    @Test func breaksCarryTheirPhase() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        timer.completeIfFinished(at: start.addingTimeInterval(25 * 60))
        timer.start(at: start.addingTimeInterval(25 * 60))
        let state = HourglassActivityAttributes.ContentState(timer: timer, now: start.addingTimeInterval(25 * 60))
        #expect(state?.phase == .shortBreak)
        #expect(state?.phaseDuration == TimeInterval(5 * 60))
    }
}
