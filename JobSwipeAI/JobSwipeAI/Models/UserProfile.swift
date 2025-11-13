import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var email: String
    var yearsOfExperience: Int
    var currentTitle: String?
    var location: String
    var workAuthorizationStatus: String
    var preferredJobTitles: [String]
    var preferredLocations: [String]
    var jobTypePreferences: [JobType]
    var salaryRange: SalaryRange?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        fullName: String = "",
        email: String = "",
        yearsOfExperience: Int = 0,
        currentTitle: String? = nil,
        location: String = "",
        workAuthorizationStatus: String = "",
        preferredJobTitles: [String] = [],
        preferredLocations: [String] = [],
        jobTypePreferences: [JobType] = JobType.allCases,
        salaryRange: SalaryRange? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.yearsOfExperience = yearsOfExperience
        self.currentTitle = currentTitle
        self.location = location
        self.workAuthorizationStatus = workAuthorizationStatus
        self.preferredJobTitles = preferredJobTitles
        self.preferredLocations = preferredLocations
        self.jobTypePreferences = jobTypePreferences
        self.salaryRange = salaryRange
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
