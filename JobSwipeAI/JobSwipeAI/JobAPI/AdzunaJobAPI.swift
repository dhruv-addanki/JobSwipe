import Foundation

struct AdzunaJobAPIConfiguration {
    var baseURL: URL = URL(string: "https://api.adzuna.com/v1/api/jobs")!
    var countryCode: String = "us"
    var appID: String
    var appKey: String
    var defaultSearchTerm: String = "ios developer"
    var defaultLocation: String? = nil
    var resultsPerPage: Int = 25

    static var `default`: AdzunaJobAPIConfiguration {
        AdzunaJobAPIConfiguration(
            appID: "<#ADZUNA_APP_ID#>",
            appKey: "<#ADZUNA_APP_KEY#>"
        )
    }

    var isConfigured: Bool {
        !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !appKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !appID.contains("<#") && !appKey.contains("<#")
    }
}

final class AdzunaJobAPI: JobAPI {
    private let httpClient: HTTPClient
    private var configuration: AdzunaJobAPIConfiguration

    var providerName: String { "Adzuna" }
    var isConfigured: Bool { configuration.isConfigured }

    init(configuration: AdzunaJobAPIConfiguration = .default, httpClient: HTTPClient? = nil) {
        self.configuration = configuration
        if let httpClient {
            self.httpClient = httpClient
        } else {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self.httpClient = URLSessionHTTPClient(baseURL: configuration.baseURL, decoder: decoder)
        }
    }

    func updateDefaultSearchTerm(_ term: String) {
        configuration.defaultSearchTerm = term
    }

    func fetchJobs(for profile: UserProfile?) async throws -> [JobPosting] {
        guard configuration.isConfigured else {
            throw APIError.notConfigured(message: "Adzuna API keys are missing. Open AdzunaJobAPIConfiguration and replace the placeholder values.")
        }

        let searchTerm = buildSearchTerm(from: profile)
        let location = buildLocation(from: profile)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "app_id", value: configuration.appID),
            URLQueryItem(name: "app_key", value: configuration.appKey),
            URLQueryItem(name: "what", value: searchTerm),
            URLQueryItem(name: "results_per_page", value: String(configuration.resultsPerPage))
        ]

        if let location {
            queryItems.append(URLQueryItem(name: "where", value: location))
        }

        let request = APIRequest(
            path: "\(configuration.countryCode)/search/1",
            queryItems: queryItems
        )

        let response: AdzunaJobResponse = try await httpClient.send(request, decodeTo: AdzunaJobResponse.self)
        return response.results.map(mapJob(_:))
    }

    func submitApplication(_ application: JobApplication) async throws -> ApplicationSubmissionResult {
        ApplicationSubmissionResult(
            success: false,
            externalId: nil,
            message: "Applications must be submitted directly via Adzuna job listings."
        )
    }

    private func buildSearchTerm(from profile: UserProfile?) -> String {
        if let titles = profile?.preferredJobTitles, !titles.isEmpty {
            return titles.joined(separator: " ")
        }
        if let jobType = profile?.currentTitle, !jobType.isEmpty {
            return jobType
        }
        return configuration.defaultSearchTerm
    }

    private func buildLocation(from profile: UserProfile?) -> String? {
        if let preferredLocation = profile?.preferredLocations.first, !preferredLocation.isEmpty {
            return preferredLocation
        }
        if let profileLocation = profile?.location, !profileLocation.isEmpty {
            return profileLocation
        }
        return configuration.defaultLocation
    }

    private func mapJob(_ job: AdzunaJob) -> JobPosting {
        let description = job.description.strippingHTML()
        let highlights = Self.extractHighlights(from: description)
        let requirementsSlice = Array(highlights.prefix(3))
        let responsibilitiesSlice = Array(highlights.dropFirst(requirementsSlice.count).prefix(3))

        return JobPosting(
            id: job.id,
            title: job.title,
            companyName: job.company?.displayName ?? "Unknown company",
            location: job.location?.displayName ?? "Remote",
            isRemote: job.inferredRemoteStatus,
            employmentType: JobType(adzunaContractTime: job.contractTime, contractType: job.contractType),
            salaryMin: job.salaryMin,
            salaryMax: job.salaryMax,
            currency: job.currency ?? "USD",
            description: description,
            requirements: requirementsSlice.isEmpty ? job.defaultRequirementsFallback : requirementsSlice,
            responsibilities: responsibilitiesSlice,
            postedAt: job.created,
            source: .api(name: providerName)
        )
    }

    private static func extractHighlights(from description: String) -> [String] {
        let newlineSet = CharacterSet.newlines
        let bulletCharacters: Set<Character> = ["•", "-"]
        var components = description
            .components(separatedBy: newlineSet)
            .flatMap { line -> [String] in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty { return [] }
                if let first = trimmedLine.first, bulletCharacters.contains(first) {
                    let content = trimmedLine.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                    return [content]
                }
                return [trimmedLine]
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 6 }

        if components.isEmpty {
            components = description
                .split(separator: ".")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 6 }
        }

        return Array(components.prefix(6))
    }
}

private struct AdzunaJobResponse: Decodable {
    let results: [AdzunaJob]
}

private struct AdzunaJob: Decodable {
    struct Company: Decodable {
        let displayName: String?
    }

    struct Location: Decodable {
        let displayName: String?
    }

    struct Category: Decodable {
        let label: String?
    }

    let id: String
    let title: String
    let description: String
    let created: Date?
    let redirectURL: String?
    let location: Location?
    let company: Company?
    let category: Category?
    let contractTime: String?
    let contractType: String?
    let salaryMin: Double?
    let salaryMax: Double?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case created
        case redirectURL = "redirect_url"
        case location
        case company
        case category
        case contractTime = "contract_time"
        case contractType = "contract_type"
        case salaryMin = "salary_min"
        case salaryMax = "salary_max"
        case currency = "salary_currency"
    }

    var defaultRequirementsFallback: [String] {
        var values: [String] = []
        if let label = category?.label { values.append(label) }
        if let contractType {
            values.append(contractType.replacingOccurrences(of: "_", with: " ").capitalized)
        }
        return values.isEmpty ? ["Reputable opportunity"] : values
    }

    var inferredRemoteStatus: Bool? {
        guard let displayName = location?.displayName else { return nil }
        return displayName.localizedCaseInsensitiveContains("remote")
    }
}

private extension JobType {
    init(adzunaContractTime: String?, contractType: String?) {
        if let contractTime = adzunaContractTime?.lowercased() {
            switch contractTime {
            case _ where contractTime.contains("part"):
                self = .partTime
                return
            case _ where contractTime.contains("intern"):
                self = .internship
                return
            default:
                break
            }
        }

        if let contractType = contractType?.lowercased(), contractType.contains("contract") {
            self = .contract
        } else {
            self = .fullTime
        }
    }
}
