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

/// A model wired to fakes and throwaway storage; pass the pieces a test wants to inspect.
@MainActor
private func makeModel(
    defaults: UserDefaults? = nil,
    notifier: FakeNotifier? = nil,
    liveActivity: FakeLiveActivity? = nil
) -> TimerModel {
    TimerModel(
        defaults: defaults ?? makeTestDefaults(),
        notifier: notifier ?? FakeNotifier(),
        liveActivity: liveActivity ?? FakeLiveActivity()
    )
}

/// Records what the model shows in the Live Activity.
@MainActor
final class FakeLiveActivity: SessionActivityControlling {
    private(set) var shown: [HourglassActivityAttributes.ContentState?] = []

    func show(_ state: HourglassActivityAttributes.ContentState?) {
        shown.append(state)
    }
}

/// Records what the model asks of the notification system.
@MainActor
final class FakeNotifier: SessionNotifying {
    private(set) var scheduled: [(endDate: Date, alert: SessionAlert)] = []
    private(set) var cancelCount = 0

    func scheduleSessionEnd(at endDate: Date, alert: SessionAlert) {
        scheduled.append((endDate, alert))
    }

    func cancelSessionEnd() {
        cancelCount += 1
    }
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
        let model = makeModel()
        model.flip(at: start)
        #expect(model.isTurnedOver)
        #expect(model.timer.isRunning)
        model.reset()
    }

    @Test func flippingWhileRunningOrPausedIsIgnored() {
        let model = makeModel()
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
        let model = makeModel()
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
        let model = makeModel()
        #expect(model.settings == PomodoroSettings())
        #expect(model.timer.settings == PomodoroSettings())
    }

    @Test func changesApplyImmediatelyWhileIdle() {
        let model = makeModel()
        model.updateSettings(shortFocus)
        #expect(!model.settingsApplyNextSession)
        #expect(model.timer.remaining(at: start) == 10 * 60)
    }

    @Test func changesWaitForTheRunningSessionToEnd() {
        let model = makeModel()
        model.toggle(at: start)
        model.updateSettings(shortFocus)

        #expect(model.settingsApplyNextSession)
        #expect(model.timer.remaining(at: start) == 25 * 60)

        model.refresh(at: start.addingTimeInterval(25 * 60))
        #expect(model.timer.phase == .shortBreak)
        #expect(model.timer.settings == shortFocus)
    }

    @Test func resetAppliesWaitingChanges() {
        let model = makeModel()
        model.toggle(at: start)
        model.updateSettings(shortFocus)
        model.reset()
        #expect(model.timer.remaining(at: start) == 10 * 60)
    }

    @Test func settingsAreSavedAcrossLaunches() {
        let defaults = makeTestDefaults()
        makeModel(defaults: defaults).updateSettings(shortFocus)
        #expect(makeModel(defaults: defaults).settings == shortFocus)
    }

    @Test func unreadableSavedDataFallsBackToDefaults() {
        let defaults = makeTestDefaults()
        defaults.set(Data("not json".utf8), forKey: "pomodoroSettings")
        #expect(makeModel(defaults: defaults).settings == PomodoroSettings())
    }
}

@MainActor
struct TimerModelNotificationTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func startingSchedulesAnAlertForTheEndOfTheSession() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.toggle(at: start)

        #expect(notifier.scheduled.count == 1)
        #expect(notifier.scheduled.last?.endDate == start.addingTimeInterval(25 * 60))
        #expect(notifier.scheduled.last?.alert.title == "Focus complete")
        model.reset()
    }

    @Test func flippingToStartSchedulesAnAlert() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.flip(at: start)
        #expect(notifier.scheduled.count == 1)
        model.reset()
    }

    @Test func pausingCancelsAndResumingReschedulesForTheNewEnd() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.toggle(at: start)
        model.toggle(at: start.addingTimeInterval(5 * 60))
        #expect(notifier.cancelCount == 1)

        let resumeTime = start.addingTimeInterval(60 * 60)
        model.toggle(at: resumeTime)
        #expect(notifier.scheduled.last?.endDate == resumeTime.addingTimeInterval(20 * 60))
        model.reset()
    }

    @Test func resetCancelsTheAlert() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.toggle(at: start)
        model.reset()
        #expect(notifier.cancelCount == 1)
    }

    @Test func finishingWithTheAppOpenCancelsTheAlert() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.toggle(at: start)
        model.refresh(at: start.addingTimeInterval(25 * 60))
        #expect(model.timer.state == .idle)
        #expect(notifier.cancelCount == 1)
    }

    @Test func alertDescribesTheBreakWithTheChosenLength() {
        let notifier = FakeNotifier()
        let model = makeModel(notifier: notifier)
        model.updateSettings(PomodoroSettings(shortBreakMinutes: 7))
        model.toggle(at: start)
        #expect(notifier.scheduled.last?.alert.body == "Time for a 7-minute break. Flip your hourglass to start it.")
        model.reset()
    }
}

@MainActor
struct TimerModelLiveActivityTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func runningSessionShowsACountdownToItsEnd() {
        let activity = FakeLiveActivity()
        let model = makeModel(liveActivity: activity)
        model.flip(at: start)

        let state = activity.shown.last ?? nil
        #expect(state?.phase == .focus)
        #expect(state?.endDate == start.addingTimeInterval(25 * 60))
        #expect(state?.isPaused == false)
        model.reset()
    }

    @Test func pausingFreezesTheCountdown() {
        let activity = FakeLiveActivity()
        let model = makeModel(liveActivity: activity)
        model.toggle(at: start)
        model.toggle(at: start.addingTimeInterval(5 * 60))
        #expect((activity.shown.last ?? nil)?.pausedRemaining == 20 * 60)
        model.reset()
    }

    @Test func resetAndCompletionEndTheActivity() {
        let activity = FakeLiveActivity()
        let model = makeModel(liveActivity: activity)
        model.toggle(at: start)
        model.reset(at: start)
        #expect(activity.shown.last == .some(nil))

        model.toggle(at: start)
        model.refresh(at: start.addingTimeInterval(25 * 60))
        #expect(activity.shown.last == .some(nil))
    }
}
