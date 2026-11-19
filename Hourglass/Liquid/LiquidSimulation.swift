import Foundation

/// What the renderer needs to draw one frame of liquid.
struct LiquidFrame: Equatable, Sendable {
    static let still = LiquidFrame(angle: 0, waveAmplitude: 0, wavePhase: 0)

    /// Surface angle in screen space, in radians.
    var angle: Double
    /// Surface roughness, 0...1.
    var waveAmplitude: Double
    /// Drives the ripple animation, in radians.
    var wavePhase: Double
}

/// Per-frame liquid state. A reference type so the view can advance it while rendering
/// without triggering another SwiftUI update.
@MainActor
final class LiquidSimulation {
    private var model = SloshModel()
    private var lastDate: Date?

    func advance(to date: Date, gravity: Gravity, reduceMotion: Bool) -> LiquidFrame {
        defer { lastDate = date }
        let target = gravity.surfaceAngle
        guard !reduceMotion else {
            model.settle(at: target)
            return LiquidFrame(angle: model.angle, waveAmplitude: 0, wavePhase: 0)
        }
        let elapsed = lastDate.map { date.timeIntervalSince($0) } ?? 0
        model.step(toward: target, seconds: elapsed)
        let wavePhase = (date.timeIntervalSinceReferenceDate * 3).truncatingRemainder(dividingBy: 2 * .pi)
        return LiquidFrame(angle: model.angle, waveAmplitude: model.waveAmplitude, wavePhase: wavePhase)
    }
}
