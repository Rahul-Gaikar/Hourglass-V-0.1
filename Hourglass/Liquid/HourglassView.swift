import SwiftUI

/// The hourglass: liquid drawn in a `Canvas`, seen through a Liquid Glass vessel.
struct HourglassView: View {
    let progress: Double
    let isFlowing: Bool
    let palette: LiquidPalette
    let frame: LiquidFrame
    var profile: HourglassProfile = .standard

    var body: some View {
        let scene = LiquidScene(
            progress: progress,
            isFlowing: isFlowing,
            palette: palette,
            frame: frame,
            profile: profile
        )
        Canvas { context, size in
            scene.draw(in: &context, size: size)
        }
        .overlay {
            Color.clear
                .glassEffect(.clear, in: HourglassShape(profile: profile))
                .overlay {
                    HourglassShape(profile: profile)
                        .stroke(.white.opacity(0.35), lineWidth: 1.5)
                }
                .allowsHitTesting(false)
        }
        // The time label carries the same information for VoiceOver.
        .accessibilityHidden(true)
    }
}

#Preview("Half drained, tilted") {
    HourglassView(
        progress: 0.4,
        isFlowing: true,
        palette: .forPhase(.focus),
        frame: LiquidFrame(angle: -0.25, waveAmplitude: 0.3, wavePhase: 1)
    )
    .padding()
    .background(.black)
}
