import Foundation

enum JobType: String, Codable, CaseIterable, Identifiable {
    case internship
    case fullTime
    case contract
    case partTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .internship: return "Internship"
        case .fullTime: return "Full-Time"
        case .contract: return "Contract"
        case .partTime: return "Part-Time"
        }
    }
}
