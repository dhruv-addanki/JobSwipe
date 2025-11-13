import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var dryRunOnly = true
    @State private var showDebugLogs = false

    var body: some View {
        Form {
            Section("LLM") {
                SecureField("API Key", text: $apiKey)
                Toggle("Dry run only", isOn: $dryRunOnly)
            }

            Section("Developer") {
                Toggle("Show debug logs", isOn: $showDebugLogs)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
