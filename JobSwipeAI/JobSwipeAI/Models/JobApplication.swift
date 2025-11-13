import Foundation
import SwiftData

@Model
final class JobApplication {
    @Attribute(.unique) var id: UUID
    var jobId: String
    var jobTitle: String
    var companyName: String
    var userProfileId: UUID
    private var statusRaw: String
    var failureMessage: String?
    var tailoredCoverLetter: String?
    var tailoredResumeSummary: String?
    var generatedQandAData: Data
    var submittedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        job: JobPosting,
        userProfileId: UUID,
        status: ApplicationStatus = .notStarted,
        tailoredCoverLetter: String? = nil,
        tailoredResumeSummary: String? = nil,
        generatedQandA: [ApplicationQuestionAnswer] = [],
        submittedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.jobId = job.id
        self.jobTitle = job.title
        self.companyName = job.companyName
        self.userProfileId = userProfileId
        self.statusRaw = status.storageValue
        self.failureMessage = {
            if case .failed(let message) = status { return message }
            return nil
        }()
        self.tailoredCoverLetter = tailoredCoverLetter
        self.tailoredResumeSummary = tailoredResumeSummary
        self.generatedQandAData = JobApplication.encodeQA(generatedQandA)
        self.submittedAt = submittedAt
        self.createdAt = createdAt
    }

    var status: ApplicationStatus {
        get {
            if statusRaw == ApplicationStatus.State.failed.rawValue, let failureMessage {
                return .failed(errorMessage: failureMessage)
            }
            return ApplicationStatus(stateRaw: statusRaw)
        }
        set {
            statusRaw = newValue.storageValue
            if case .failed(let message) = newValue {
                failureMessage = message
            }
        }
    }

    var generatedQandA: [ApplicationQuestionAnswer] {
        get { JobApplication.decodeQA(from: generatedQandAData) }
        set { generatedQandAData = JobApplication.encodeQA(newValue) }
    }

    private static func encodeQA(_ values: [ApplicationQuestionAnswer]) -> Data {
        let encoder = JSONEncoder()
        return (try? encoder.encode(values)) ?? Data()
    }

    private static func decodeQA(from data: Data) -> [ApplicationQuestionAnswer] {
        let decoder = JSONDecoder()
        return (try? decoder.decode([ApplicationQuestionAnswer].self, from: data)) ?? []
    }
}

private extension ApplicationStatus {
    enum State: String {
        case notStarted
        case draftGenerated
        case submitted
        case failed
    }

    var storageValue: String {
        switch self {
        case .notStarted:
            return State.notStarted.rawValue
        case .draftGenerated:
            return State.draftGenerated.rawValue
        case .submitted:
            return State.submitted.rawValue
        case .failed:
            return State.failed.rawValue
        }
    }

    init(stateRaw: String) {
        switch stateRaw {
        case State.draftGenerated.rawValue:
            self = .draftGenerated
        case State.submitted.rawValue:
            self = .submitted
        case State.failed.rawValue:
            self = .failed(errorMessage: "")
        default:
            self = .notStarted
        }
    }
}
