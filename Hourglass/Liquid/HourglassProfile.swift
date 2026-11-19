import Foundation

/// The hourglass silhouette and the liquid levels it holds, in unit coordinates.
///
/// Each bulb is measured by `t`: 0 at the neck, 1 at the bulb's far end (top of the top bulb,
/// bottom of the bottom bulb). Half-widths are fractions of the glass's widest half-width.
/// Areas are in the same units, so they can be compared but not mapped directly to points.
struct HourglassProfile: Sendable {
    static let standard = HourglassProfile()

    /// Half-width of the neck, as a fraction of the widest point.
    let neckHalfWidth: Double
    /// Share of one bulb's volume that is liquid.
    let fillRatio: Double

    private static let sampleCount = 256
    /// `cumulativeArea[i]` is the area of one bulb from the neck up to `t = i / sampleCount`.
    private let cumulativeArea: [Double]

    init(neckHalfWidth: Double = 0.05, fillRatio: Double = 0.75) {
        let neck = neckHalfWidth.clamped(to: 0.01...0.5)
        self.neckHalfWidth = neck
        self.fillRatio = fillRatio.clamped(to: 0.05...0.95)

        let step = 1 / Double(Self.sampleCount)
        var areas = [0.0]
        areas.reserveCapacity(Self.sampleCount + 1)
        for index in 1...Self.sampleCount {
            let midpoint = (Double(index) - 0.5) * step
            let width = Self.halfWidth(at: midpoint, neckHalfWidth: neck)
            areas.append(areas[index - 1] + width * step)
        }
        cumulativeArea = areas
    }

    /// Half-width of the glass at `t`.
    func halfWidth(at t: Double) -> Double {
        Self.halfWidth(at: t, neckHalfWidth: neckHalfWidth)
    }

    /// Area of one bulb.
    var bulbArea: Double {
        cumulativeArea[Self.sampleCount]
    }

    /// Total liquid in the glass.
    var liquidArea: Double {
        bulbArea * fillRatio
    }

    /// Area of one bulb between the neck and `t`.
    func area(upTo t: Double) -> Double {
        let position = t.clamped(to: 0...1) * Double(Self.sampleCount)
        let lower = min(Int(position), Self.sampleCount - 1)
        let fraction = position - Double(lower)
        return cumulativeArea[lower] + (cumulativeArea[lower + 1] - cumulativeArea[lower]) * fraction
    }

    /// Height of the liquid surface in the top bulb, which drains from full (progress 0) to empty (1).
    func topLevel(progress: Double) -> Double {
        level(forArea: liquidArea * (1 - progress.clamped(to: 0...1)))
    }

    /// Height of the liquid surface in the bottom bulb, which fills from the far end up toward the neck.
    func bottomLevel(progress: Double) -> Double {
        level(forArea: bulbArea - liquidArea * progress.clamped(to: 0...1))
    }

    /// The `t` at which the area measured from the neck equals `area`.
    private func level(forArea area: Double) -> Double {
        let target = area.clamped(to: 0...bulbArea)
        var low = 0
        var high = Self.sampleCount
        while high - low > 1 {
            let middle = (low + high) / 2
            if cumulativeArea[middle] < target {
                low = middle
            } else {
                high = middle
            }
        }
        let span = cumulativeArea[high] - cumulativeArea[low]
        let fraction = span > 0 ? (target - cumulativeArea[low]) / span : 0
        return (Double(low) + fraction) / Double(Self.sampleCount)
    }

    /// Narrow at the neck, opening into a rounded bulb that is widest (and flat-walled) at its far end.
    private static func halfWidth(at t: Double, neckHalfWidth: Double) -> Double {
        let t = t.clamped(to: 0...1)
        let opening = 1 - pow(1 - t, 2.4)
        return neckHalfWidth + (1 - neckHalfWidth) * opening
    }
}
