import Foundation
import Testing

@testable import Hourglass

@MainActor
struct TimerModelTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func idleHourglassLooksDrainedSoFlippingDoesNotJump() {
        let timer = PomodoroTimer()
        #expect(timer.liquidProgress(at: start) == 1)
    }

    @Test func runningHourglassShowsRealProgress() {
        var timer = PomodoroTimer()
        timer.start(at: start)
        #expect(timer.liquidProgress(at: start) == 0)
    }

    @Test func flippingWhileIdleTurnsTheHourglassOverAndStarts() {
        let model = TimerModel()
        model.flip(at: start)
        #expect(model.isTurnedOver)
        #expect(model.timer.isRunning)
        model.reset()
    }

    @Test func flippingWhileRunningOrPausedIsIgnored() {
        let model = TimerModel()
        model.toggle(at: start)
        model.flip(at: start.addingTimeInterval(60))
        #expect(!model.isTurnedOver)
        #expect(model.timer.remaining(at: start.addingTimeInterval(60)) == 24 * 60)

        model.toggle(at: start.addingTimeInterval(60))
        model.flip(at: start.addingTimeInterval(120))
        #expect(!model.isTurnedOver)
        #expect(model.timer.state == .paused(remaining: 24 * 60))
        model.reset()
    }

    @Test func eachFlipTurnsTheHourglassBack() {
        let model = TimerModel()
        model.flip(at: start)
        model.reset()
        model.flip(at: start)
        #expect(!model.isTurnedOver)
        model.reset()
    }
}
