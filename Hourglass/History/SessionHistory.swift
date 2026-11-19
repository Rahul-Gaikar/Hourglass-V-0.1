import Foundation
import SwiftData

/// Receives each phase as it completes. A protocol so tests can record calls.
@MainActor
protocol SessionRecording: AnyObject {
    func record(_ completed: CompletedPhase)
}

/// Saves completed focus sessions with SwiftData. Breaks aren't kept: a pomodoro is the focus part.
@MainActor
final class SwiftDataSessionHistory: SessionRecording {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func record(_ completed: CompletedPhase) {
        guard completed.phase == .focus else { return }
        context.insert(FocusSession(endedAt: completed.endedAt, duration: completed.duration))
        // Autosave would also persist it; saving now means it survives the app being killed right after.
        // If saving fails, the session still shows for this launch and autosave retries.
        try? context.save()
    }
}

enum HistoryStore {
    /// The on-disk store, or an in-memory one if it can't be opened, so the app always launches.
    /// In that case history works for this launch only and the existing file is left untouched.
    static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: FocusSession.self)
        } catch {
            // An in-memory store has no file to fail on.
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: FocusSession.self, configurations: memoryOnly)
        }
    }
}
