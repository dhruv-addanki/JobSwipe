import Foundation
import SwiftData

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var form = ProfileFormData()
    @Published var resumeText: String = ""
    @Published var alertMessage: String?
    @Published private(set) var isSavingProfile = false
    @Published private(set) var isSavingResume = false

    private var cachedProfile: UserProfile?
    private var cachedResume: ResumeDocument?

    func load(profile: UserProfile?, resume: ResumeDocument?) {
        cachedProfile = profile
        cachedResume = resume
        if let profile {
            form = ProfileFormData(model: profile)
        }
        if let resume {
            resumeText = resume.rawText
        }
    }

    func saveProfile(using context: ModelContext) {
        isSavingProfile = true
        defer { isSavingProfile = false }

        let profile = cachedProfile ?? UserProfile()
        profile.fullName = form.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.yearsOfExperience = Int(form.yearsOfExperience) ?? 0
        profile.currentTitle = form.currentTitle.isEmpty ? nil : form.currentTitle
        profile.location = form.location
        profile.workAuthorizationStatus = form.workAuthorizationStatus
        profile.preferredJobTitles = form.preferredJobTitles
        profile.preferredLocations = form.preferredLocations
        profile.jobTypePreferences = Array(form.selectedJobTypes).sorted { $0.rawValue < $1.rawValue }
        profile.salaryRange = form.salaryRange
        profile.updatedAt = .now

        if cachedProfile == nil {
            profile.createdAt = .now
            context.insert(profile)
        }

        do {
            try context.save()
            cachedProfile = profile
        } catch {
            alertMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }

    func saveResume(using context: ModelContext) {
        isSavingResume = true
        defer { isSavingResume = false }

        let trimmed = resumeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let resume = cachedResume ?? ResumeDocument()
        resume.rawText = trimmed
        resume.lastUpdated = .now

        if cachedResume == nil {
            context.insert(resume)
        }

        do {
            try context.save()
            cachedResume = resume
        } catch {
            alertMessage = "Failed to save resume: \(error.localizedDescription)"
        }
    }
}

struct ProfileFormData {
    var fullName: String = ""
    var email: String = ""
    var yearsOfExperience: String = "0"
    var currentTitle: String = ""
    var location: String = ""
    var workAuthorizationStatus: String = ""
    var preferredJobTitlesText: String = ""
    var preferredLocationsText: String = ""
    var selectedJobTypes: Set<JobType> = Set(JobType.allCases)
    var salaryMinimum: String = ""
    var salaryMaximum: String = ""

    init() {}

    init(model: UserProfile) {
        self.fullName = model.fullName
        self.email = model.email
        self.yearsOfExperience = String(model.yearsOfExperience)
        self.currentTitle = model.currentTitle ?? ""
        self.location = model.location
        self.workAuthorizationStatus = model.workAuthorizationStatus
        self.preferredJobTitlesText = model.preferredJobTitles.joined(separator: ", ")
        self.preferredLocationsText = model.preferredLocations.joined(separator: ", ")
        self.selectedJobTypes = Set(model.jobTypePreferences)
        if let salaryRange = model.salaryRange {
            self.salaryMinimum = String(Int(salaryRange.minimum))
            self.salaryMaximum = String(Int(salaryRange.maximum))
        }
    }

    var preferredJobTitles: [String] {
        preferredJobTitlesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var preferredLocations: [String] {
        preferredLocationsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var salaryRange: SalaryRange? {
        guard let min = Double(salaryMinimum), let max = Double(salaryMaximum), min >= 0, max >= 0 else {
            return nil
        }
        return SalaryRange(minimum: min, maximum: max)
    }
}
