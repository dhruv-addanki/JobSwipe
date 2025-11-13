import Foundation

enum ApplicationStatus: Equatable, Codable {
    case notStarted
    case draftGenerated
    case submitted
    case failed(errorMessage: String)

    private enum CodingKeys: String, CodingKey {
        case state
        case errorMessage
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .notStarted:
            try container.encode("notStarted", forKey: .state)
        case .draftGenerated:
            try container.encode("draftGenerated", forKey: .state)
        case .submitted:
            try container.encode("submitted", forKey: .state)
        case .failed(let message):
            try container.encode("failed", forKey: .state)
            try container.encode(message, forKey: .errorMessage)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let state = try container.decode(String.self, forKey: .state)
        switch state {
        case "notStarted":
            self = .notStarted
        case "draftGenerated":
            self = .draftGenerated
        case "submitted":
            self = .submitted
        case "failed":
            let message = try container.decode(String.self, forKey: .errorMessage)
            self = .failed(errorMessage: message)
        default:
            self = .notStarted
        }
    }
}

struct ApplicationQuestionAnswer: Codable, Hashable {
    let question: String
    let answer: String
}

struct JobMatchScore: Codable, Hashable {
    let jobId: String
    let score: Double
    let reasons: [String]
}

struct JobPosting: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let companyName: String
    let location: String
    let isRemote: Bool?
    let employmentType: JobType
    let salaryMin: Double?
    let salaryMax: Double?
    let currency: String?
    let description: String
    let requirements: [String]
    let responsibilities: [String]
    let postedAt: Date?
    let source: JobSource

    var salaryDescription: String {
        guard let min = salaryMin, let max = salaryMax else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        let minText = formatter.string(from: min as NSNumber) ?? ""
        let maxText = formatter.string(from: max as NSNumber) ?? ""
        return "\(minText) - \(maxText)"
    }

    var tags: [String] {
        var values: [String] = []
        if let isRemote {
            values.append(isRemote ? "Remote" : "Onsite")
        }
        values.append(employmentType.displayName)
        return values
    }
}
