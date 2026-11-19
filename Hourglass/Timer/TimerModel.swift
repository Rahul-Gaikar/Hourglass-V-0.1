import Foundation
import Observation

/// Owns the running pomodoro and the user's durations, and makes sure a phase advances when its time is up.
@MainActor
@Observable
final class TimerModel {
    private static let settingsKey = "pomodoroSettings"

    private(set) var timer: PomodoroTimer
    /// The durations the user has chosen. They reach the timer only while it's idle, so editing them
    /// mid-session never makes the liquid jump; otherwise they apply from the next session.
    private(set) var settings: PomodoroSettings
    /// Whether the hourglass is currently drawn upside down, because the phone was turned over to start.
    private(set) var isTurnedOver = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let notifier: any SessionNotifying
    @ObservationIgnored private let liveActivity: any SessionActivityControlling
    @ObservationIgnored private var completionTask: Task<Void, Never>?

    /// `notifier` and `liveActivity` default to the real system services; tests pass fakes.
    init(
        defaults: UserDefaults = .standard,
        notifier: (any SessionNotifying)? = nil,
        liveActivity: (any SessionActivityControlling)? = nil
    ) {
        self.defaults = defaults
        self.notifier = notifier ?? SessionNotifier()
        self.liveActivity = liveActivity ?? SessionActivityController()
        let settings = Self.loadSettings(from: defaults)
        self.settings = settings
        self.timer = PomodoroTimer(settings: settings)
    }

    /// Whether changed settings will wait for the current session to end.
    var settingsApplyNextSession: Bool {
        timer.state != .idle
    }

    func updateSettings(_ newSettings: PomodoroSettings) {
        guard newSettings != settings else { return }
        settings = newSettings
        saveSettings()
        applySettingsIfIdle()
    }

    /// Starts or resumes when stopped, pauses when running.
    func toggle(at now: Date = .now) {
        if timer.isRunning {
            timer.pause(at: now)
        } else {
            timer.start(at: now)
        }
        scheduleCompletion(from: now)
        syncOutsideViews(at: now)
    }

    /// Turning the phone over starts the next session, like turning over a real hourglass.
    /// The drained bottom bulb becomes the full top one. Ignored unless idle, so a fumble can't
    /// restart a session in progress.
    func flip(at now: Date = .now) {
        guard timer.state == .idle else { return }
        isTurnedOver.toggle()
        timer.start(at: now)
        scheduleCompletion(from: now)
        syncOutsideViews(at: now)
    }

    func reset(at now: Date = .now) {
        timer.reset()
        completionTask?.cancel()
        applySettingsIfIdle()
        syncOutsideViews(at: now)
    }

    /// Advances the phase if it has ended. Call when the app returns to the foreground.
    func refresh(at now: Date = .now) {
        timer.completeIfFinished(at: now)
        applySettingsIfIdle()
        scheduleCompletion(from: now)
        syncOutsideViews(at: now)
    }

    /// Keeps everything shown outside the app in step with the timer: the Live Activity while a
    /// session is running or paused, and the "session ended" alert while it's running.
    /// When a session ends with the app open, the alert is cancelled so it doesn't pop up over the hourglass.
    private func syncOutsideViews(at now: Date) {
        liveActivity.show(HourglassActivityAttributes.ContentState(timer: timer, now: now))
        guard case .running(let endDate) = timer.state else {
            notifier.cancelSessionEnd()
            return
        }
        // The next phase's length comes from `settings`, which is what the timer will use by then.
        let alert = SessionAlert(finishing: timer.phase, next: timer.nextPhase, settings: settings)
        notifier.scheduleSessionEnd(at: endDate, alert: alert)
    }

    private func applySettingsIfIdle() {
        guard timer.state == .idle, timer.settings != settings else { return }
        timer.settings = settings
    }

    private func scheduleCompletion(from now: Date) {
        completionTask?.cancel()
        guard timer.isRunning else { return }
        let delay = timer.remaining(at: now)
        completionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }

    // MARK: - Persistence

    /// Saved settings, or the defaults when nothing is saved or the data can't be read.
    private static func loadSettings(from defaults: UserDefaults) -> PomodoroSettings {
        guard let data = defaults.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(PomodoroSettings.self, from: data)
        else { return PomodoroSettings() }
        return settings
    }

    private func saveSettings() {
        // Encoding a struct of plain integers can't realistically fail; if it ever did, the
        // change still applies for this launch and the previous saved value is kept.
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.settingsKey)
    }
}
