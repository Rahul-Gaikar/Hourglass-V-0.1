import Foundation
import UserNotifications

/// Schedules the single "session ended" alert. A protocol so tests can record calls instead of
/// touching the real notification system.
@MainActor
protocol SessionNotifying: AnyObject {
    /// Replaces any pending alert with one that fires at `endDate`.
    func scheduleSessionEnd(at endDate: Date, alert: SessionAlert)
    func cancelSessionEnd()
}

/// Local notifications through `UNUserNotificationCenter`.
///
/// Permission is requested the first time a session is scheduled rather than at launch. If it's
/// refused, scheduling quietly does nothing and the timer works the same.
@MainActor
final class SessionNotifier: SessionNotifying {
    private static let identifier = "session-end"

    /// Bumped on every schedule or cancel. A schedule that was waiting on the permission prompt
    /// checks it before adding the alert, so a pause made meanwhile can't be undone by a stale request.
    private var generation = 0

    func scheduleSessionEnd(at endDate: Date, alert: SessionAlert) {
        generation += 1
        let scheduledGeneration = generation
        Task {
            let granted =
                (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]))
                ?? false
            // Measured after the prompt, which can take a while to answer.
            let delay = endDate.timeIntervalSinceNow
            guard granted, scheduledGeneration == generation, delay > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
            // No completion handler: it would be called off the main actor, and a failure needs no handling
            // beyond the alert not appearing.
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    func cancelSessionEnd() {
        generation += 1
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}
