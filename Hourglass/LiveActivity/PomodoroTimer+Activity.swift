import Foundation

extension HourglassActivityAttributes.ContentState {
    /// What the Live Activity should show for `timer` at `now`, or `nil` while idle:
    /// no activity is shown between sessions.
    init?(timer: PomodoroTimer, now: Date) {
        switch timer.state {
        case .idle:
            return nil
        case .running(let endDate):
            self.init(phase: timer.phase, endDate: endDate, phaseDuration: timer.phaseDuration, pausedRemaining: nil)
        case .paused(let remaining):
            self.init(
                phase: timer.phase,
                endDate: now.addingTimeInterval(remaining),
                phaseDuration: timer.phaseDuration,
                pausedRemaining: remaining
            )
        }
    }
}
