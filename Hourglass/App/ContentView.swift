import SwiftUI

/// Placeholder root screen until the v0.1 core flow is defined.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Hourglass")
                .font(.largeTitle.bold())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
