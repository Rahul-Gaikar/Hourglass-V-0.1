/// A stage of the pomodoro cycle.
enum SessionPhase: String, Codable, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak

    var isBreak: Bool {
        self != .focus
    }

    var title: String {
        switch self {
        case .focus:
            "Focus"
        case .shortBreak:
            "Short break"
        case .longBreak:
            "Long break"
        }
    }
}
