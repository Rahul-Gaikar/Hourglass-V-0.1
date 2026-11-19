import Foundation

enum TimeLabel {
    /// Remaining time as `m:ss`, rounded up so the label reads 25:00 at the start and 0:00 only at the very end.
    static func text(for remaining: TimeInterval) -> String {
        let totalSeconds = Int(max(0, remaining).rounded(.up))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return seconds < 10 ? "\(minutes):0\(seconds)" : "\(minutes):\(seconds)"
    }
}
