import SwiftData
import SwiftUI

/// The last week of focus sessions, in a Liquid Glass panel drawn inside the timer screen
/// so it turns with the hourglass.
struct HistoryPanel: View {
    static let daysShown = 7

    let onDone: () -> Void
    @Query private var sessions: [FocusSession]

    init(now: Date = .now, onDone: @escaping () -> Void) {
        self.onDone = onDone
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let cutoff = calendar.date(byAdding: .day, value: -(Self.daysShown - 1), to: today) ?? today
        _sessions = Query(
            filter: #Predicate<FocusSession> { $0.endedAt >= cutoff },
            sort: \.endedAt,
            order: .reverse
        )
    }

    private var days: [HistoryDay] {
        HistorySummary.days(from: sessions.map { ($0.endedAt, $0.duration) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("History")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.glassProminent)
            }

            if days.isEmpty {
                Text("No sessions this week yet. Flip your hourglass to start one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(days) { day in
                    LabeledContent {
                        Text(HistorySummary.describe(day))
                            .monospacedDigit()
                    } label: {
                        Text(day.day, format: .dateTime.weekday(.wide).day().month())
                    }
                }
            }
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .padding(.horizontal, 16)
    }
}

/// A small glass button showing today's count; opens the history panel.
struct TodayHistoryButton: View {
    let action: () -> Void
    @Query private var today: [FocusSession]

    init(now: Date = .now, action: @escaping () -> Void) {
        self.action = action
        let startOfDay = Calendar.current.startOfDay(for: now)
        _today = Query(filter: #Predicate<FocusSession> { $0.endedAt >= startOfDay })
    }

    var body: some View {
        Button(action: action) {
            Label(Self.title(todayCount: today.count), systemImage: "checkmark.circle")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 6)
        }
        .buttonStyle(.glass)
        .accessibilityHint("Shows your session history")
    }

    static func title(todayCount: Int) -> String {
        todayCount == 0 ? "History" : "\(todayCount) today"
    }
}

#Preview {
    HistoryPanel(onDone: {})
        .modelContainer(for: FocusSession.self, inMemory: true)
        .preferredColorScheme(.dark)
}
