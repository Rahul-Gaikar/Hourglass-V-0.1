import Foundation
import Testing

@testable import Hourglass

/// A throwaway defaults store, so tests never touch the app's real settings.
private func makeTestDefaults() -> UserDefaults {
    let name = "TimerModelTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

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
        let model = TimerModel(defaults: makeTestDefaults())
        model.flip(at: start)
        #expect(model.isTurnedOver)
        #expect(model.timer.isRunning)
        model.reset()
    }

    @Test func flippingWhileRunningOrPausedIsIgnored() {
        let model = TimerModel(defaults: makeTestDefaults())
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
        let model = TimerModel(defaults: makeTestDefaults())
        model.flip(at: start)
        model.reset()
        model.flip(at: start)
        #expect(!model.isTurnedOver)
        model.reset()
    }
}

@MainActor
struct TimerModelSettingsTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let shortFocus = PomodoroSettings(focusMinutes: 10)

    @Test func startsWithClassicDurationsWhenNothingIsSaved() {
        let model = TimerModel(defaults: makeTestDefaults())
        #expect(model.settings == PomodoroSettings())
        #expect(model.timer.settings == PomodoroSettings())
    }

    @Test func changesApplyImmediatelyWhileIdle() {
        let model = TimerModel(defaults: makeTestDefaults())
        model.updateSettings(shortFocus)
        #expect(!model.settingsApplyNextSession)
        #expect(model.timer.remaining(at: start) == 10 * 60)
    }

    @Test func changesWaitForTheRunningSessionToEnd() {
        let model = TimerModel(defaults: makeTestDefaults())
        model.toggle(at: start)
        model.updateSettings(shortFocus)

        #expect(model.settingsApplyNextSession)
        #expect(model.timer.remaining(at: start) == 25 * 60)

        model.refresh(at: start.addingTimeInterval(25 * 60))
        #expect(model.timer.phase == .shortBreak)
        #expect(model.timer.settings == shortFocus)
    }

    @Test func resetAppliesWaitingChanges() {
        let model = TimerModel(defaults: makeTestDefaults())
        model.toggle(at: start)
        model.updateSettings(shortFocus)
        model.reset()
        #expect(model.timer.remaining(at: start) == 10 * 60)
    }

    @Test func settingsAreSavedAcrossLaunches() {
        let defaults = makeTestDefaults()
        TimerModel(defaults: defaults).updateSettings(shortFocus)
        #expect(TimerModel(defaults: defaults).settings == shortFocus)
    }

    @Test func unreadableSavedDataFallsBackToDefaults() {
        let defaults = makeTestDefaults()
        defaults.set(Data("not json".utf8), forKey: "pomodoroSettings")
        #expect(TimerModel(defaults: defaults).settings == PomodoroSettings())
    }
}
