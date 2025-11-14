import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var apiKey: String = ""
    @State private var dryRunOnly = true
    @State private var showDebugLogs = false
    @State private var remoteSearchTerm: String = ""

    private var mockToggleBinding: Binding<Bool> {
        Binding(
            get: { environment.useMockJobs },
            set: { environment.useMockJobs = $0 }
        )
    }

    var body: some View {
        Form {
            Section("Job Data") {
                Toggle("Use mock job feed", isOn: mockToggleBinding)
                TextField("Remote search keywords", text: $remoteSearchTerm)
                    .textInputAutocapitalization(.never)
                Text("Provider: \(environment.currentJobProviderName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !environment.isRemoteProviderConfigured {
                    Label {
                        Text("Add your Adzuna API keys in AdzunaJobAPI.swift to enable live data.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section("LLM") {
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                Toggle("Dry run only", isOn: $dryRunOnly)
            }

            Section("Developer") {
                Toggle("Show debug logs", isOn: $showDebugLogs)
            }
        }
        .onAppear {
            remoteSearchTerm = environment.remoteSearchTerm
        }
        .onChange(of: remoteSearchTerm) { newValue in
            environment.remoteSearchTerm = newValue
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppEnvironment())
    }
}
