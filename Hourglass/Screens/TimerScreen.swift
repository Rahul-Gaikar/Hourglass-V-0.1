import SwiftUI

/// The hourglass fills the display, with the time and controls floating on top in Liquid Glass.
/// Turning the phone over starts a session; the whole screen turns with it so it stays readable.
struct TimerScreen: View {
    /// How often to check for a flip. Well above human flipping speed, far below the frame rate.
    private static let flipCheckInterval = Duration.milliseconds(50)

    @State private var model = TimerModel()
    @State private var simulation = LiquidSimulation()
    @State private var motion = MotionProvider()
    @State private var flipDetector = FlipDetector()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let now = context.date
            let timer = model.timer
            let frame = simulation.advance(to: now, gravity: orientedGravity, reduceMotion: reduceMotion)
            ZStack {
                HourglassView(
                    progress: timer.liquidProgress(at: now),
                    isFlowing: timer.isRunning,
                    palette: .forPhase(timer.phase),
                    frame: frame
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                VStack {
                    header(timer: timer, now: now)
                    Spacer()
                    controls(timer: timer)
                }
                .padding(.vertical, 24)
            }
            .rotationEffect(.degrees(model.isTurnedOver ? 180 : 0))
        }
        .background(background)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.start, trigger: model.isTurnedOver)
        .task { await watchForFlips() }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refresh()
                motion.start()
            } else {
                motion.stop()
            }
        }
    }

    /// Gravity relative to the hourglass as it's currently drawn.
    private var orientedGravity: Gravity {
        model.isTurnedOver ? motion.gravity.turnedOver : motion.gravity
    }

    /// Runs outside view updates, so starting the timer here doesn't mutate state mid-render.
    private func watchForFlips() async {
        while !Task.isCancelled {
            if flipDetector.update(gravity: orientedGravity, at: .now) {
                model.flip()
            }
            try? await Task.sleep(for: Self.flipCheckInterval)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.03, green: 0.04, blue: 0.09), Color(red: 0.10, green: 0.08, blue: 0.20)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func header(timer: PomodoroTimer, now: Date) -> some View {
        VStack(spacing: 2) {
            Text(timer.phase.title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.7))
            Text(TimeLabel.text(for: timer.remaining(at: now)))
                .font(.system(size: 60, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            if timer.state == .idle {
                Label("Flip to start", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .accessibilityElement(children: .combine)
    }

    private func controls(timer: PomodoroTimer) -> some View {
        HStack(spacing: 24) {
            Button {
                model.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .disabled(timer.state == .idle)
            .accessibilityLabel("Reset")

            Button {
                model.toggle()
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(LiquidPalette.forPhase(timer.phase).depth)
            .accessibilityLabel(timer.isRunning ? "Pause" : "Start")
        }
    }
}

#Preview {
    TimerScreen()
}
