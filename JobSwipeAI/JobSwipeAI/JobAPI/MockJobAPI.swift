import Foundation

final class MockJobAPI: JobAPI {
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "MockJobAPI")

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchJobs(for profile: UserProfile?) async throws -> [JobPosting] {
        try await Task.sleep(nanoseconds: UInt64.random(in: 400_000_000...900_000_000))
        let data = try await loadMockData()
        return try decoder.decode([JobPosting].self, from: data)
    }

    func submitApplication(_ application: JobApplication) async throws -> ApplicationSubmissionResult {
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...800_000_000))
        return ApplicationSubmissionResult(
            success: true,
            externalId: UUID().uuidString,
            message: "Mock submission queued"
        )
    }

    private func loadMockData() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard let url = Bundle.main.url(forResource: "mock_jobs", withExtension: "json") else {
                    continuation.resume(throwing: APIError.missingData)
                    return
                }
                do {
                    let data = try Data(contentsOf: url)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
