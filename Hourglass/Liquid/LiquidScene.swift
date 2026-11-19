import SwiftUI

/// Liquid colours for a phase: warm while focusing, cool on a break.
struct LiquidPalette: Sendable {
    let surface: Color
    let depth: Color

    static func forPhase(_ phase: SessionPhase) -> LiquidPalette {
        if phase.isBreak {
            return LiquidPalette(
                surface: Color(red: 0.40, green: 0.93, blue: 0.86),
                depth: Color(red: 0.10, green: 0.42, blue: 0.95)
            )
        }
        return LiquidPalette(
            surface: Color(red: 1.00, green: 0.76, blue: 0.32),
            depth: Color(red: 0.95, green: 0.34, blue: 0.16)
        )
    }
}

/// Draws one frame of liquid. A plain value with no actor isolation, so it can render inside a `Canvas`.
struct LiquidScene: Sendable {
    let progress: Double
    let isFlowing: Bool
    let palette: LiquidPalette
    let frame: LiquidFrame
    let profile: HourglassProfile

    private static let surfaceSamples = 48

    func draw(in context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        guard rect.width > 0, rect.height > 0 else { return }

        let slope = CGFloat(tan(frame.angle))
        let ripple = CGFloat(frame.waveAmplitude) * rect.width * 0.02
        let topSurfaceY = profile.point(t: profile.topLevel(progress: progress), side: 0, bulb: .top, in: rect).y
        let bottomSurfaceY =
            profile.point(t: profile.bottomLevel(progress: progress), side: 0, bulb: .bottom, in: rect).y

        if progress < 1 {
            fill(.top, surfaceY: topSurfaceY, slope: slope, ripple: ripple, in: rect, context: context)
        }
        if isFlowing, progress < 1 {
            drawStream(toSurfaceY: bottomSurfaceY, in: rect, context: context)
        }
        if progress > 0 {
            // The falling stream keeps the bottom surface gently disturbed.
            let splash: CGFloat = isFlowing ? 1.5 : 0
            fill(.bottom, surfaceY: bottomSurfaceY, slope: slope, ripple: ripple + splash, in: rect, context: context)
        }
    }

    private func fill(
        _ bulb: Bulb,
        surfaceY: CGFloat,
        slope: CGFloat,
        ripple: CGFloat,
        in rect: CGRect,
        context: GraphicsContext
    ) {
        var layer = context
        layer.clip(to: profile.bulbPath(bulb, in: rect))

        let surface = surfacePoints(y: surfaceY, slope: slope, ripple: ripple, in: rect)
        guard let first = surface.first, let last = surface.last else { return }

        var body = Path()
        body.addLines(surface)
        body.addLine(to: CGPoint(x: last.x, y: rect.maxY + rect.height))
        body.addLine(to: CGPoint(x: first.x, y: rect.maxY + rect.height))
        body.closeSubpath()

        let farEnd = profile.point(t: 1, side: 0, bulb: bulb, in: rect)
        layer.fill(
            body,
            with: .linearGradient(
                Gradient(colors: [palette.surface, palette.depth]),
                startPoint: CGPoint(x: rect.midX, y: surfaceY),
                endPoint: CGPoint(x: rect.midX, y: max(farEnd.y, surfaceY + 1))
            )
        )

        var highlight = Path()
        highlight.addLines(surface)
        layer.stroke(highlight, with: .color(.white.opacity(0.45)), lineWidth: 1.5)
    }

    /// A thin stream falling from the neck along gravity into the bottom bulb.
    private func drawStream(toSurfaceY surfaceY: CGFloat, in rect: CGRect, context: GraphicsContext) {
        var layer = context
        layer.clip(to: profile.bulbPath(.bottom, in: rect))

        let neck = CGPoint(x: rect.midX, y: rect.midY)
        let angle = frame.angle
        // Overshoot a little so the stream disappears into the liquid rather than stopping at its surface.
        let length = max(0, (surfaceY - neck.y) / CGFloat(cos(angle))) + 24
        let end = CGPoint(
            x: neck.x - CGFloat(sin(angle)) * length,
            y: neck.y + CGFloat(cos(angle)) * length
        )

        var stream = Path()
        stream.move(to: neck)
        stream.addLine(to: end)
        layer.stroke(
            stream,
            with: .linearGradient(
                Gradient(colors: [palette.surface, palette.depth]),
                startPoint: neck,
                endPoint: end
            ),
            style: StrokeStyle(lineWidth: max(2, CGFloat(profile.neckHalfWidth) * rect.width * 0.6), lineCap: .round)
        )
    }

    private func surfacePoints(y: CGFloat, slope: CGFloat, ripple: CGFloat, in rect: CGRect) -> [CGPoint] {
        let margin = rect.width * 0.25
        let span = rect.width + 2 * margin
        return (0...Self.surfaceSamples).map { index in
            let x = rect.minX - margin + span * CGFloat(index) / CGFloat(Self.surfaceSamples)
            let wave = ripple * CGFloat(sin(Double(x / rect.width) * 4 * .pi + frame.wavePhase))
            return CGPoint(x: x, y: y + slope * (x - rect.midX) + wave)
        }
    }
}
