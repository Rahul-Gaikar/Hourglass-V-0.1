import Foundation
import Testing

@testable import Hourglass

struct PomodoroTimerTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func idleTimerShowsFullFocusDuration() {
        let timer = PomodoroTimer()
        #expect(timer.phase == .focus)
        #expect(timer.state == .idle)
        #expect(timer.remaining(at: start) == 25 * 60)
        #expect(timer.progress(at: start) == 0)
    }

    @Test func runningTimerCountsDownFromStart() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        #expect(timer.isRunning)
        #expect(timer.remaining(at: start.addingTimeInterval(60)) == 24 * 60)
        #expect(timer.progress(at: start.addingTimeInterval(12.5 * 60)) == 0.5)
    }

    @Test func remainingAndProgressStayInBoundsAfterTheEnd() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        let muchLater = start.addingTimeInterval(10 * 60 * 60)
        #expect(timer.remaining(at: muchLater) == 0)
        #expect(timer.progress(at: muchLater) == 1)
    }

    @Test func startingAgainWhileRunningDoesNotRestart() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        timer.start(at: start.addingTimeInterval(10 * 60))
        #expect(timer.remaining(at: start.addingTimeInterval(10 * 60)) == 15 * 60)
    }

    @Test func pauseFreezesTimeAndStartResumesIt() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        timer.pause(at: start.addingTimeInterval(5 * 60))

        let anHourLater = start.addingTimeInterval(60 * 60)
        #expect(timer.state == .paused(remaining: 20 * 60))
        #expect(timer.remaining(at: anHourLater) == 20 * 60)

        timer.start(at: anHourLater)
        #expect(timer.remaining(at: anHourLater.addingTimeInterval(60)) == 19 * 60)
    }

    @Test func pausingAfterTheEndDoesNothing() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        let afterEnd = start.addingTimeInterval(26 * 60)
        timer.pause(at: afterEnd)
        #expect(timer.isRunning)
        #expect(timer.completeIfFinished(at: afterEnd) != nil)
    }

    @Test func resetReturnsToTheStartOfTheSamePhase() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        timer.reset()
        #expect(timer.state == .idle)
        #expect(timer.phase == .focus)
        #expect(timer.completedFocusSessions == 0)
    }

    @Test func completionIsReportedOnlyOnceTheEndDateIsReached() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        let end = start.addingTimeInterval(25 * 60)

        #expect(timer.completeIfFinished(at: end.addingTimeInterval(-1)) == nil)
        #expect(timer.isRunning)

        // The app may only notice long after the phase ended; the real end time is reported.
        let completed = timer.completeIfFinished(at: end.addingTimeInterval(60 * 60))
        #expect(completed == CompletedPhase(phase: .focus, endedAt: end, duration: 25 * 60))
        #expect(timer.phase == .shortBreak)
        #expect(timer.state == .idle)
        #expect(timer.completeIfFinished(at: end.addingTimeInterval(60 * 60)) == nil)
    }

    @Test func longBreakFollowsTheConfiguredNumberOfFocusSessions() {
        var timer = PomodoroTimer(settings: PomodoroSettings(sessionsBeforeLongBreak: 2))
        var now = start
        var phasesAfterEachCompletion: [SessionPhase] = []

        for _ in 0..<4 {
            timer.start(at: now)
            now = now.addingTimeInterval(timer.phaseDuration)
            timer.completeIfFinished(at: now)
            phasesAfterEachCompletion.append(timer.phase)
        }

        #expect(phasesAfterEachCompletion == [.shortBreak, .focus, .longBreak, .focus])
        #expect(timer.completedFocusSessions == 0)
    }

    @Test func breakUsesItsOwnDuration() {
        var timer = PomodoroTimer(settings: PomodoroSettings(focusMinutes: 1, shortBreakMinutes: 3))
        timer.start(at: start)
        timer.completeIfFinished(at: start.addingTimeInterval(60))
        #expect(timer.phase == .shortBreak)
        #expect(timer.remaining(at: start) == 3 * 60)
    }
}

struct PomodoroTimerNextPhaseTests {
    @Test func nextPhaseMatchesWhatCompletionActuallyDoes() {
        var timer = PomodoroTimer(settings: PomodoroSettings(sessionsBeforeLongBreak: 2))
        var now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        for _ in 0..<6 {
            let predicted = timer.nextPhase
            timer.start(at: now)
            now = now.addingTimeInterval(timer.phaseDuration)
            timer.completeIfFinished(at: now)
            #expect(timer.phase == predicted)
        }
    }
}
