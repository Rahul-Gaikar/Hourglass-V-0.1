import Foundation
import Observation

/// Owns the running pomodoro and makes sure a phase advances when its time is up.
@MainActor
@Observable
final class TimerModel {
    private(set) var timer: PomodoroTimer
    /// Whether the hourglass is currently drawn upside down, because the phone was turned over to start.
    private(set) var isTurnedOver = false
    @ObservationIgnored private var completionTask: Task<Void, Never>?

    init(timer: PomodoroTimer = PomodoroTimer()) {
        self.timer = timer
    }

    /// Starts or resumes when stopped, pauses when running.
    func toggle(at now: Date = .now) {
        if timer.isRunning {
            timer.pause(at: now)
        } else {
            timer.start(at: now)
        }
        scheduleCompletion(from: now)
    }

    /// Turning the phone over starts the next session, like turning over a real hourglass.
    /// The drained bottom bulb becomes the full top one. Ignored unless idle, so a fumble can't
    /// restart a session in progress.
    func flip(at now: Date = .now) {
        guard timer.state == .idle else { return }
        isTurnedOver.toggle()
        timer.start(at: now)
        scheduleCompletion(from: now)
    }

    func reset() {
        timer.reset()
        completionTask?.cancel()
    }

    /// Advances the phase if it has ended. Call when the app returns to the foreground.
    func refresh(at now: Date = .now) {
        timer.completeIfFinished(at: now)
        scheduleCompletion(from: now)
    }

    private func scheduleCompletion(from now: Date) {
        completionTask?.cancel()
        guard timer.isRunning else { return }
        let delay = timer.remaining(at: now)
        completionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.timer.completeIfFinished(at: .now)
        }
    }
}
