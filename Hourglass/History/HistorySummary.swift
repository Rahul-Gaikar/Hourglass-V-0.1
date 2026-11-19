import Foundation

/// Focus sessions completed on one calendar day.
struct HistoryDay: Equatable, Identifiable, Sendable {
    /// Start of the day.
    let day: Date
    let sessionCount: Int
    let focusMinutes: Int

    var id: Date {
        day
    }
}

enum HistorySummary {
    /// Groups sessions by calendar day, newest day first. Days with no sessions are left out.
    static func days(
        from sessions: [(endedAt: Date, duration: TimeInterval)],
        calendar: Calendar = .current
    ) -> [HistoryDay] {
        let byDay = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.endedAt) }
        return byDay.map { day, sessions in
            let seconds = sessions.reduce(0) { $0 + $1.duration }
            return HistoryDay(day: day, sessionCount: sessions.count, focusMinutes: Int((seconds / 60).rounded()))
        }
        .sorted { $0.day > $1.day }
    }

    /// "1 session · 25 min", "4 sessions · 100 min".
    static func describe(_ day: HistoryDay) -> String {
        let sessions = day.sessionCount == 1 ? "1 session" : "\(day.sessionCount) sessions"
        return "\(sessions) · \(day.focusMinutes) min"
    }
}
