import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen and Dynamic Island presentation of a running session.
///
/// The countdown and progress bar are driven by the system from the dates in the state, so they
/// keep moving while the app is suspended. Once the end date passes, the activity goes stale and
/// shows that the session is complete.
struct HourglassLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HourglassActivityAttributes.self) { context in
            LockScreenView(state: context.state, isComplete: context.isStale)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.4))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            let palette = LiquidPalette.forPhase(state.phase)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(state.phase.title, systemImage: "hourglass")
                        .font(.headline)
                        .foregroundStyle(palette.surface)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownText(state: state, isComplete: context.isStale)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DrainBar(state: state, isComplete: context.isStale)
                }
            } compactLeading: {
                Image(systemName: "hourglass")
                    .foregroundStyle(palette.surface)
            } compactTrailing: {
                CountdownText(state: state, isComplete: context.isStale)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "hourglass")
                    .foregroundStyle(palette.surface)
            }
            .keylineTint(palette.surface)
        }
    }
}

private struct LockScreenView: View {
    let state: HourglassActivityAttributes.ContentState
    let isComplete: Bool

    var body: some View {
        let palette = LiquidPalette.forPhase(state.phase)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(state.phase.title, systemImage: "hourglass")
                    .font(.headline)
                    .foregroundStyle(palette.surface)
                Spacer()
                CountdownText(state: state, isComplete: isComplete)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            DrainBar(state: state, isComplete: isComplete)
            if isComplete {
                Text("Session complete · flip your hourglass to continue")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            } else if state.isPaused {
                Text("Paused")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

/// Remaining time: ticking while running, frozen while paused, "Done" once complete.
private struct CountdownText: View {
    let state: HourglassActivityAttributes.ContentState
    let isComplete: Bool

    var body: some View {
        if isComplete {
            Text("Done")
        } else if let remaining = state.pausedRemaining {
            Text(TimeLabel.text(for: remaining))
        } else {
            Text(timerInterval: state.startDate...state.endDate, countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// The top bulb, as a bar that drains from full to empty.
private struct DrainBar: View {
    let state: HourglassActivityAttributes.ContentState
    let isComplete: Bool

    var body: some View {
        let tint = LiquidPalette.forPhase(state.phase).depth
        Group {
            if isComplete {
                ProgressView(value: 0)
            } else if let remaining = state.pausedRemaining {
                ProgressView(value: max(0, min(1, remaining / state.phaseDuration)))
            } else {
                ProgressView(timerInterval: state.startDate...state.endDate, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(tint)
    }
}
