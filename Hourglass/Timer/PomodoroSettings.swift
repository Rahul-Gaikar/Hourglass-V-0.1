import Foundation

/// User-adjustable lengths for the pomodoro cycle.
///
/// Values are stored as entered and clamped when read, so a bad value (from an old build or a
/// corrupted store) can never produce a zero-length or absurdly long session.
struct PomodoroSettings: Codable, Equatable, Sendable {
    static let minuteRange = 1...120
    static let sessionsBeforeLongBreakRange = 1...12

    var focusMinutes = 25
    var shortBreakMinutes = 5
    var longBreakMinutes = 15
    var sessionsBeforeLongBreak = 4

    /// Length of `phase` in seconds.
    func duration(for phase: SessionPhase) -> TimeInterval {
        let minutes: Int
        switch phase {
        case .focus:
            minutes = focusMinutes
        case .shortBreak:
            minutes = shortBreakMinutes
        case .longBreak:
            minutes = longBreakMinutes
        }
        return TimeInterval(minutes.clamped(to: Self.minuteRange) * 60)
    }

    /// Number of focus sessions that earn a long break.
    var effectiveSessionsBeforeLongBreak: Int {
        sessionsBeforeLongBreak.clamped(to: Self.sessionsBeforeLongBreakRange)
    }
}
