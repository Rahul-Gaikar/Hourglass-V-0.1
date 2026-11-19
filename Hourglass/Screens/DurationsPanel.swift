import SwiftUI

/// A Liquid Glass panel for editing the pomodoro durations.
///
/// Drawn inside the timer screen rather than as a sheet, so it turns with the hourglass and stays
/// readable after the phone has been flipped.
struct DurationsPanel: View {
    @Binding var settings: PomodoroSettings
    /// Shown as a note when edits will wait for the current session to end.
    let appliesNextSession: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Durations")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.glassProminent)
            }

            minutesStepper("Focus", value: $settings.focusMinutes)
            minutesStepper("Short break", value: $settings.shortBreakMinutes)
            minutesStepper("Long break", value: $settings.longBreakMinutes)

            Stepper(
                value: $settings.sessionsBeforeLongBreak,
                in: PomodoroSettings.sessionsBeforeLongBreakRange
            ) {
                LabeledContent("Long break every") {
                    Text(Self.sessionsText(settings.sessionsBeforeLongBreak))
                        .monospacedDigit()
                }
            }

            HStack {
                Button("Reset to defaults") {
                    settings = PomodoroSettings()
                }
                .font(.footnote)
                .disabled(settings == PomodoroSettings())
                Spacer()
                if appliesNextSession {
                    Text("Applies from the next session")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
        .padding(.horizontal, 16)
    }

    private func minutesStepper(_ title: String, value: Binding<Int>) -> some View {
        Stepper(value: value, in: PomodoroSettings.minuteRange) {
            LabeledContent(title) {
                Text("\(value.wrappedValue) min")
                    .monospacedDigit()
            }
        }
    }

    static func sessionsText(_ count: Int) -> String {
        count == 1 ? "1 focus session" : "\(count) focus sessions"
    }
}

#Preview {
    @Previewable @State var settings = PomodoroSettings()
    DurationsPanel(settings: $settings, appliesNextSession: true, onDone: {})
        .preferredColorScheme(.dark)
}
