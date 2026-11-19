/// The words of the notification shown when a session ends while the app isn't open.
struct SessionAlert: Equatable, Sendable {
    let title: String
    let body: String

    init(finishing phase: SessionPhase, next: SessionPhase, settings: PomodoroSettings) {
        switch phase {
        case .focus:
            let minutes = Int(settings.duration(for: next) / 60)
            let kind = next == .longBreak ? "long break" : "break"
            title = "Focus complete"
            body = "Time for a \(minutes)-minute \(kind). Flip your hourglass to start it."
        case .shortBreak, .longBreak:
            title = "Break's over"
            body = "Flip your hourglass when you're ready to focus."
        }
    }
}
