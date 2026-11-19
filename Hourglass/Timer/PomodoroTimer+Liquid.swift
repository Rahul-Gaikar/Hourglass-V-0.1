import Foundation

extension PomodoroTimer {
    /// How drained the hourglass should look at `now`, from 0 (top bulb full) to 1 (all liquid at the bottom).
    ///
    /// An idle timer is shown drained, like an hourglass waiting to be turned over, so flipping
    /// the phone to start moves the liquid without it jumping.
    func liquidProgress(at now: Date) -> Double {
        state == .idle ? 1 : progress(at: now)
    }
}
