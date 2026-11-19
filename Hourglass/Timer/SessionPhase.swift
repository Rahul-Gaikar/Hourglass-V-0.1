/// A stage of the pomodoro cycle.
enum SessionPhase: String, Codable, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak

    var isBreak: Bool {
        self != .focus
    }
}
