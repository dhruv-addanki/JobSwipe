import Foundation

struct ApplicationSubmissionResult: Codable {
    let success: Bool
    let externalId: String?
    let message: String?
}

protocol JobAPI: AnyObject {
    func fetchJobs(for profile: UserProfile?) async throws -> [JobPosting]
    func submitApplication(_ application: JobApplication) async throws -> ApplicationSubmissionResult
}
