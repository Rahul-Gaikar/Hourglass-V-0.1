import ActivityKit
import Foundation

/// Shows, updates and ends the session's Live Activity. A protocol so tests can record calls.
@MainActor
protocol SessionActivityControlling: AnyObject {
    /// Shows `state`, or ends the activity when it's `nil`.
    func show(_ state: HourglassActivityAttributes.ContentState?)
}

/// Live Activities through ActivityKit. If the user has turned them off, this quietly does nothing.
@MainActor
final class SessionActivityController: SessionActivityControlling {
    private var activity: Activity<HourglassActivityAttributes>?

    init() {
        // A relaunch after the app was killed starts with an idle timer, so any activity left over
        // from the previous run is out of date.
        let leftovers = Activity<HourglassActivityAttributes>.activities
        Task {
            for activity in leftovers {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func show(_ state: HourglassActivityAttributes.ContentState?) {
        guard let state else {
            end()
            return
        }
        // Stale once the phase is due to end, so the Lock Screen can say it's complete
        // even if the app isn't running to update it.
        let content = ActivityContent(state: state, staleDate: state.isPaused ? nil : state.endDate)
        if let activity {
            Task { await activity.update(content) }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // A failure (e.g. too many activities) just means no Lock Screen countdown this session.
        activity = try? Activity.request(attributes: HourglassActivityAttributes(), content: content)
    }

    private func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
