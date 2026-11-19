import Foundation
import SwiftData

/// A completed focus session, kept on-device for the history view.
///
/// This is the first version of the store's schema. Changing a stored property later needs a
/// `VersionedSchema` and a migration plan so existing history is preserved.
@Model
final class FocusSession {
    /// When the session ended.
    var endedAt: Date
    /// How long it was, in seconds.
    var duration: TimeInterval

    init(endedAt: Date, duration: TimeInterval) {
        self.endedAt = endedAt
        self.duration = duration
    }
}
