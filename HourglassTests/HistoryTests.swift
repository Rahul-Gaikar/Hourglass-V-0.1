import Foundation
import SwiftData
import Testing

@testable import Hourglass

struct HistorySummaryTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-11-19 00:00 UTC.
    private let dayStart = Date(timeIntervalSince1970: 1_795_046_400)

    @Test func noSessionsMeansNoDays() {
        #expect(HistorySummary.days(from: [], calendar: calendar).isEmpty)
    }

    @Test func sessionsAreGroupedByDayNewestFirst() {
        let hour: TimeInterval = 60 * 60
        let sessions: [(endedAt: Date, duration: TimeInterval)] = [
            (dayStart.addingTimeInterval(-2 * hour), 25 * 60),  // the day before
            (dayStart.addingTimeInterval(9 * hour), 25 * 60),
            (dayStart.addingTimeInterval(10 * hour), 50 * 60),
        ]
        let days = HistorySummary.days(from: sessions, calendar: calendar)

        #expect(days.count == 2)
        #expect(days[0] == HistoryDay(day: dayStart, sessionCount: 2, focusMinutes: 75))
        #expect(days[1].day == dayStart.addingTimeInterval(-24 * hour))
        #expect(days[1].sessionCount == 1)
    }

    @Test func dayDescriptionIsPluralisedCorrectly() {
        let one = HistoryDay(day: dayStart, sessionCount: 1, focusMinutes: 25)
        let four = HistoryDay(day: dayStart, sessionCount: 4, focusMinutes: 100)
        #expect(HistorySummary.describe(one) == "1 session · 25 min")
        #expect(HistorySummary.describe(four) == "4 sessions · 100 min")
    }

    @Test func todayButtonShowsTheCountOnceThereIsOne() {
        #expect(TodayHistoryButton.title(todayCount: 0) == "History")
        #expect(TodayHistoryButton.title(todayCount: 3) == "3 today")
    }
}

@MainActor
struct SwiftDataSessionHistoryTests {
    private let end = Date(timeIntervalSinceReferenceDate: 1_000_000)

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: FocusSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func completedFocusSessionsAreSaved() throws {
        let context = try makeContext()
        SwiftDataSessionHistory(context: context)
            .record(CompletedPhase(phase: .focus, endedAt: end, duration: 25 * 60))

        let saved = try context.fetch(FetchDescriptor<FocusSession>())
        #expect(saved.count == 1)
        #expect(saved.first?.endedAt == end)
        #expect(saved.first?.duration == TimeInterval(25 * 60))
    }

    @Test(arguments: [SessionPhase.shortBreak, .longBreak])
    func breaksAreNotSaved(phase: SessionPhase) throws {
        let context = try makeContext()
        SwiftDataSessionHistory(context: context)
            .record(CompletedPhase(phase: phase, endedAt: end, duration: 5 * 60))
        #expect(try context.fetchCount(FetchDescriptor<FocusSession>()) == 0)
    }
}
