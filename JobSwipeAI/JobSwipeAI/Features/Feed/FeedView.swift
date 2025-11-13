import SwiftUI
import SwiftData

struct FeedView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @StateObject private var viewModel = FeedViewModel()

    private var taskToken: FeedTaskToken {
        FeedTaskToken(profileID: profiles.first?.id, apiID: environment.jobAPISourceID)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView("Fetching curated jobs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.jobs.isEmpty {
                ContentUnavailableView(
                    "No matches yet",
                    systemImage: "rectangle.stack.badge.person.crop",
                    description: Text("Save your profile to unlock personalized job matches.")
                )
            } else {
                List {
                    Section(\"Source: \\(environment.currentJobProviderName)\") {
                        ForEach(viewModel.jobs) { job in
                            FeedJobCardView(job: job)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await reloadJobs()
                }
            }
        }
        .task(id: taskToken) {
            await reloadJobs()
        }
        .animation(.easeInOut, value: viewModel.jobs)
        .navigationTitle("Matches")
        .alert("Unable to fetch jobs", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func reloadJobs() async {
        viewModel.updateJobAPI(environment.jobAPI)
        await viewModel.loadJobs(for: profiles.first)
    }
}

private struct FeedTaskToken: Hashable {
    let profileID: UUID?
    let apiID: ObjectIdentifier
}

#Preview {
    NavigationStack {
        FeedView()
            .modelContainer(ModelContainerProvider.shared(inMemory: true))
            .environmentObject(AppEnvironment(useMockJobs: true))
    }
}
