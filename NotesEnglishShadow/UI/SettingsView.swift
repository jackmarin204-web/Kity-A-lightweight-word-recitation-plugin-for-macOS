import SwiftUI

struct SettingsView: View {
    @AppStorage("enabled") private var enabled = true
    @AppStorage("fadeDuration") private var fadeDuration = 3.0

    var body: some View {
        Form {
            Toggle("Enable learning cues", isOn: $enabled)

            Picker("Card duration", selection: $fadeDuration) {
                Text("1 second").tag(1.0)
                Text("2 seconds").tag(2.0)
                Text("3 seconds").tag(3.0)
            }

            Text("This app observes only Apple Notes while it is active. It processes at most 48 characters around the cursor in memory, never stores note text, never records keystrokes, and never connects to the internet.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .formStyle(.grouped)
        .frame(width: 430)
        .padding(.vertical, 8)
        .onChange(of: enabled) { _ in notifyChange() }
        .onChange(of: fadeDuration) { _ in notifyChange() }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .shadowSettingsDidChange, object: nil)
    }
}
