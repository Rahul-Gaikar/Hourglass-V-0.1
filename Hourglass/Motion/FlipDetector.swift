import Foundation

/// Recognises the phone being turned upside down, like turning over a real hourglass.
///
/// Feed it gravity in the hourglass's current frame (so "up" is whichever end is currently the top
/// bulb). It reports a flip once the top end has pointed down for `holdDuration`, then stays quiet
/// until the phone is the right way up again in that frame.
struct FlipDetector: Sendable {
    /// How strongly gravity must point toward the top edge, in g. 1 is perfectly upside down.
    var threshold = 0.75
    /// How long the phone must stay upside down, so a wobble or a fumble doesn't count.
    var holdDuration: TimeInterval = 0.3

    private var invertedSince: Date?
    private var isArmed = true

    /// Returns `true` exactly once per flip.
    mutating func update(gravity: Gravity, at now: Date) -> Bool {
        if gravity.y < 0 {
            // The current top end points up again (or the phone is tipped that way): ready for the next flip.
            isArmed = true
        }
        guard isArmed, gravity.y > threshold else {
            invertedSince = nil
            return false
        }
        guard let since = invertedSince else {
            invertedSince = now
            return false
        }
        guard now.timeIntervalSince(since) >= holdDuration else { return false }
        invertedSince = nil
        isArmed = false
        return true
    }
}
