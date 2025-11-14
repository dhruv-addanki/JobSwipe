import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case decodingFailed
    case serverError(statusCode: Int)
    case transport(Error)
    case missingData
    case notConfigured(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .decodingFailed:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server responded with code \(code)"
        case .transport(let error):
            return error.localizedDescription
        case .missingData:
            return "Response missing required data"
        case .notConfigured(let message):
            return message
        }
    }
}
