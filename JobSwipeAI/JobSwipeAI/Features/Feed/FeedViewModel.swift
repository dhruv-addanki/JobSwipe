import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var jobs: [JobPosting] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var swipeHistory: [SwipeDecision] = []
    @Published private(set) var lastDecision: SwipeDecision?

    private var jobAPI: JobAPI

    init(jobAPI: JobAPI = MockJobAPI()) {
        self.jobAPI = jobAPI
    }

    func updateJobAPI(_ jobAPI: JobAPI) {
        self.jobAPI = jobAPI
    }

    func loadJobs(for profile: UserProfile?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetchedJobs = try await jobAPI.fetchJobs(for: profile)
            swipeHistory.removeAll()
            lastDecision = nil
            jobs = fetchedJobs
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func performSwipe(_ action: SwipeAction) {
        guard let job = jobs.first else { return }
        jobs.removeFirst()
        let decision = SwipeDecision(job: job, action: action, timestamp: Date())
        swipeHistory.append(decision)
        lastDecision = decision
    }

    func undoLastSwipe() {
        guard let previous = swipeHistory.popLast() else { return }
        jobs.insert(previous.job, at: 0)
        lastDecision = nil
    }
}

extension FeedViewModel {
    enum SwipeAction: String {
        case apply
        case reject

        var title: String {
            switch self {
            case .apply: return "Apply"
            case .reject: return "Pass"
            }
        }

        var systemImage: String {
            switch self {
            case .apply: return "checkmark.circle.fill"
            case .reject: return "xmark.circle.fill"
            }
        }
    }

    struct SwipeDecision: Identifiable {
        let id = UUID()
        let job: JobPosting
        let action: SwipeAction
        let timestamp: Date
    }
}
