import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var jobs: [JobPosting] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let jobAPI: JobAPI

    init(jobAPI: JobAPI) {
        self.jobAPI = jobAPI
    }

    func loadJobs(for profile: UserProfile?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            jobs = try await jobAPI.fetchJobs(for: profile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
