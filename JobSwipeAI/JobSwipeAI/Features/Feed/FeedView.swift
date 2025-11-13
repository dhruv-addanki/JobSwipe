import SwiftUI
import SwiftData

struct FeedView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @StateObject private var viewModel: FeedViewModel

    init(jobAPI: JobAPI) {
        _viewModel = StateObject(wrappedValue: FeedViewModel(jobAPI: jobAPI))
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
                    ForEach(viewModel.jobs) { job in
                        FeedJobCardView(job: job)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadJobs(for: profiles.first)
                }
            }
        }
        .task(id: profiles.first?.id) {
            await viewModel.loadJobs(for: profiles.first)
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
}

#Preview {
    NavigationStack {
        FeedView(jobAPI: MockJobAPI())
            .modelContainer(ModelContainerProvider.shared(inMemory: true))
    }
}
