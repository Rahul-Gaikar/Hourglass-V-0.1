import SwiftData
import SwiftUI

@main
struct HourglassApp: App {
    private let container = HistoryStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            TimerScreen(history: SwiftDataSessionHistory(context: container.mainContext))
        }
        .modelContainer(container)
    }
}
