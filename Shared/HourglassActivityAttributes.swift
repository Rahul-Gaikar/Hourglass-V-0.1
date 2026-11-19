import ActivityKit
import Foundation

/// The Live Activity shown on the Lock Screen and in the Dynamic Island while a session runs.
/// Shared by the app (which starts and updates it) and the widget extension (which draws it).
struct HourglassActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        var phase: SessionPhase
        /// When the phase ends if left running. While paused, where it would end if resumed now.
        var endDate: Date
        /// Full length of the phase, for the progress bar.
        var phaseDuration: TimeInterval
        /// Set while paused: the countdown is frozen at this many seconds.
        var pausedRemaining: TimeInterval?

        /// When a phase of this length would have started to end at `endDate`, for the system-driven countdown.
        var startDate: Date {
            endDate.addingTimeInterval(-phaseDuration)
        }

        var isPaused: Bool {
            pausedRemaining != nil
        }
    }
}
