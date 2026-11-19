import SwiftUI

/// Which half of the hourglass.
enum Bulb: Sendable {
    case top
    case bottom
}

extension HourglassProfile {
    private static let pointsPerSide = 48

    /// Converts a bulb coordinate to a point in `rect`. `side` is -1 (left edge) to 1 (right edge).
    func point(t: Double, side: Double, bulb: Bulb, in rect: CGRect) -> CGPoint {
        let direction: CGFloat = bulb == .top ? -1 : 1
        return CGPoint(
            x: rect.midX + CGFloat(side * halfWidth(at: t)) * rect.width / 2,
            y: rect.midY + direction * CGFloat(t) * rect.height / 2
        )
    }

    /// One closed bulb, from the neck out to its far end.
    func bulbPath(_ bulb: Bulb, in rect: CGRect) -> Path {
        Path { path in
            let samples = (0...Self.pointsPerSide).map { Double($0) / Double(Self.pointsPerSide) }
            path.move(to: point(t: 0, side: 1, bulb: bulb, in: rect))
            for t in samples.dropFirst() {
                path.addLine(to: point(t: t, side: 1, bulb: bulb, in: rect))
            }
            for t in samples.reversed() {
                path.addLine(to: point(t: t, side: -1, bulb: bulb, in: rect))
            }
            path.closeSubpath()
        }
    }

    /// The whole glass.
    func outline(in rect: CGRect) -> Path {
        var path = bulbPath(.top, in: rect)
        path.addPath(bulbPath(.bottom, in: rect))
        return path
    }
}

/// The hourglass silhouette, used for the glass and for clipping.
struct HourglassShape: Shape {
    let profile: HourglassProfile

    nonisolated func path(in rect: CGRect) -> Path {
        profile.outline(in: rect)
    }
}
