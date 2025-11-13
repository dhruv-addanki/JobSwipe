import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \ResumeDocument.lastUpdated) private var resumes: [ResumeDocument]
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isImportingResume = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileCard
                preferencesCard
                resumeCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: saveProfile) {
                    if viewModel.isSavingProfile {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.isSavingProfile)
            }
        }
        .fileImporter(isPresented: $isImportingResume, allowedContentTypes: [.plainText]) { result in
            switch result {
            case .success(let url):
                importResume(from: url)
            case .failure(let error):
                viewModel.alertMessage = "Failed to import file: \(error.localizedDescription)"
            }
        }
        .alert("Something went wrong", isPresented: Binding<Bool>(
            get: { viewModel.alertMessage != nil },
            set: { _ in viewModel.alertMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .onAppear {
            viewModel.load(profile: profiles.first, resume: resumes.first)
        }
        .onChange(of: profiles) { newValue in
            viewModel.load(profile: newValue.first, resume: resumes.first)
        }
        .onChange(of: resumes) { newValue in
            viewModel.load(profile: profiles.first, resume: newValue.first)
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            header(title: "Basic Info", caption: "Tell us who you are and how recruiters can reach you.")
            Group {
                TextField("Full name", text: $viewModel.form.fullName)
                TextField("Email", text: $viewModel.form.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Current title", text: $viewModel.form.currentTitle)
                TextField("Location (City, Country)", text: $viewModel.form.location)
                TextField("Work authorization", text: $viewModel.form.workAuthorizationStatus)
                TextField("Years of experience", text: $viewModel.form.yearsOfExperience)
                    .keyboardType(.numberPad)
            }
            .textFieldStyle(.roundedBorder)
            Button(action: saveProfile) {
                Label("Update profile", systemImage: "square.and.arrow.down.on.square")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSavingProfile)
        }
        .cardStyle()
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            header(title: "Job Preferences", caption: "Guide the matching engine with your target roles.")
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred job titles (comma separated)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("e.g. iOS Engineer, Mobile Architect", text: $viewModel.form.preferredJobTitlesText)
                    .textFieldStyle(.roundedBorder)

                Text("Preferred locations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("e.g. Remote, San Francisco, Toronto", text: $viewModel.form.preferredLocationsText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Job types")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(JobType.allCases) { type in
                    Toggle(type.displayName, isOn: Binding(
                        get: { viewModel.form.selectedJobTypes.contains(type) },
                        set: { isOn in
                            if isOn {
                                viewModel.form.selectedJobTypes.insert(type)
                            } else {
                                viewModel.form.selectedJobTypes.remove(type)
                            }
                        }
                    ))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Salary target (USD)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Min", text: $viewModel.form.salaryMinimum)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Max", text: $viewModel.form.salaryMaximum)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .cardStyle()
    }

    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            header(title: "Resumé", caption: "Paste or import your latest resume. We'll use it for AI-tailored applications.")

            TextEditor(text: $viewModel.resumeText)
                .frame(minHeight: 200)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            HStack {
                Button(action: { isImportingResume = true }) {
                    Label("Import .txt", systemImage: "doc.badge.plus")
                }
                Spacer()
                Button(action: saveResume) {
                    if viewModel.isSavingResume {
                        ProgressView()
                    } else {
                        Label("Update resume", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSavingResume || viewModel.resumeText.isEmpty)
            }
        }
        .cardStyle()
    }

    private func header(title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .bold()
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func saveProfile() {
        viewModel.saveProfile(using: modelContext)
    }

    private func saveResume() {
        viewModel.saveResume(using: modelContext)
    }

    private func importResume(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            viewModel.alertMessage = "Unable to access the selected file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            viewModel.resumeText = text
        } catch {
            viewModel.alertMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(ModelContainerProvider.shared(inMemory: true))
    }
}
