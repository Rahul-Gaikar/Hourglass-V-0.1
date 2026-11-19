import SwiftUI

/// The hourglass fills the display, with the time and controls floating on top in Liquid Glass.
struct TimerScreen: View {
    @State private var model = TimerModel()
    @State private var simulation = LiquidSimulation()
    @State private var motion = MotionProvider()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let now = context.date
            let timer = model.timer
            let frame = simulation.advance(to: now, gravity: motion.gravity, reduceMotion: reduceMotion)
            ZStack {
                HourglassView(
                    progress: timer.progress(at: now),
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
        }
        .background(background)
        .preferredColorScheme(.dark)
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
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: Capsule())
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
