import Foundation

/// A phase that ran to the end.
struct CompletedPhase: Equatable, Sendable {
    let phase: SessionPhase
    /// When the phase actually ended, which can be well before the app noticed (e.g. while suspended).
    let endedAt: Date
}

/// The pomodoro state machine.
///
/// A value type driven entirely by timestamps passed in by the caller: it never reads the clock
/// itself, so it stays correct across backgrounding and relaunches and is deterministic to test.
struct PomodoroTimer: Codable, Equatable, Sendable {
    enum State: Codable, Equatable, Sendable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    var settings: PomodoroSettings
    private(set) var phase: SessionPhase = .focus
    private(set) var state: State = .idle
    /// Focus sessions finished since the last long break started.
    private(set) var completedFocusSessions = 0

    init(settings: PomodoroSettings = PomodoroSettings()) {
        self.settings = settings
    }

    var phaseDuration: TimeInterval {
        settings.duration(for: phase)
    }

    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }

    /// Seconds left in the current phase at `now`.
    func remaining(at now: Date) -> TimeInterval {
        switch state {
        case .idle:
            return phaseDuration
        case .running(let endDate):
            return max(0, endDate.timeIntervalSince(now))
        case .paused(let remaining):
            return remaining
        }
    }

    /// Fraction of the current phase that has elapsed at `now`, from 0 (full top bulb) to 1 (empty).
    func progress(at now: Date) -> Double {
        (1 - remaining(at: now) / phaseDuration).clamped(to: 0...1)
    }

    /// Starts the current phase, or resumes it if paused. Does nothing while already running.
    mutating func start(at now: Date) {
        switch state {
        case .idle:
            state = .running(endDate: now.addingTimeInterval(phaseDuration))
        case .paused(let remaining):
            state = .running(endDate: now.addingTimeInterval(remaining))
        case .running:
            break
        }
    }

    /// Freezes the countdown. Does nothing unless running with time left.
    mutating func pause(at now: Date) {
        let timeLeft = remaining(at: now)
        guard isRunning, timeLeft > 0 else { return }
        state = .paused(remaining: timeLeft)
    }

    /// Abandons the current phase and returns to its start, without counting it as completed.
    mutating func reset() {
        state = .idle
    }

    /// If the running phase has ended by `now`, advances to the next phase (left idle until the
    /// user starts it) and reports what finished. Otherwise returns `nil` and changes nothing.
    @discardableResult
    mutating func completeIfFinished(at now: Date) -> CompletedPhase? {
        guard case .running(let endDate) = state, now >= endDate else { return nil }
        let completed = CompletedPhase(phase: phase, endedAt: endDate)
        moveToNextPhase()
        return completed
    }

    /// The phase that will follow the current one when it completes.
    var nextPhase: SessionPhase {
        switch phase {
        case .focus:
            let earnsLongBreak = completedFocusSessions + 1 >= settings.effectiveSessionsBeforeLongBreak
            return earnsLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    private mutating func moveToNextPhase() {
        let next = nextPhase
        if phase == .focus {
            completedFocusSessions = next == .longBreak ? 0 : completedFocusSessions + 1
        }
        phase = next
        state = .idle
    }
}
