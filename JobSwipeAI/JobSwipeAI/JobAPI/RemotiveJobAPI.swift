import Foundation

struct RemotiveJobAPIConfiguration {
    var baseURL: URL = URL(string: "https://remotive.com/api")!
    var defaultSearchTerm: String = "iOS Engineer"
    var category: String = "software-dev"
    var maxResults: Int = 30

    static let `default` = RemotiveJobAPIConfiguration()
}

final class RemotiveJobAPI: JobAPI {
    private let httpClient: HTTPClient
    private var configuration: RemotiveJobAPIConfiguration

    var providerName: String { "Remotive" }

    init(configuration: RemotiveJobAPIConfiguration = .default, httpClient: HTTPClient? = nil) {
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
        let searchTerm = buildSearchTerm(from: profile)
        var queryItems = [URLQueryItem(name: "search", value: searchTerm)]
        queryItems.append(URLQueryItem(name: "limit", value: String(configuration.maxResults)))
        queryItems.append(URLQueryItem(name: "category", value: configuration.category))

        let request = APIRequest(path: "remote-jobs", queryItems: queryItems)
        let response: RemotiveJobResponse = try await httpClient.send(request, decodeTo: RemotiveJobResponse.self)
        return response.jobs.map(mapJob(_:))
    }

    func submitApplication(_ application: JobApplication) async throws -> ApplicationSubmissionResult {
        ApplicationSubmissionResult(
            success: false,
            externalId: nil,
            message: "Remotive listings do not support programmatic submissions."
        )
    }

    private func buildSearchTerm(from profile: UserProfile?) -> String {
        if let preferred = profile?.preferredJobTitles, !preferred.isEmpty {
            return preferred.joined(separator: " ")
        }
        if let currentTitle = profile?.currentTitle, !currentTitle.isEmpty {
            return currentTitle
        }
        return configuration.defaultSearchTerm
    }

    private func mapJob(_ job: RemotiveJob) -> JobPosting {
        let (salaryMin, salaryMax, currency) = SalaryParser.parse(job.salary)
        return JobPosting(
            id: String(job.id),
            title: job.title,
            companyName: job.companyName,
            location: job.candidateRequiredLocation,
            isRemote: true,
            employmentType: JobType(jobTypeString: job.jobType),
            salaryMin: salaryMin,
            salaryMax: salaryMax,
            currency: currency,
            description: job.description.strippingHTML(),
            requirements: job.tags,
            responsibilities: job.tags,
            postedAt: job.publicationDate,
            source: .api(name: providerName)
        )
    }
}

private struct RemotiveJobResponse: Decodable {
    let jobs: [RemotiveJob]
}

private struct RemotiveJob: Decodable {
    let id: Int
    let title: String
    let companyName: String
    let companyLogo: String?
    let url: String
    let jobType: String
    let publicationDate: Date?
    let candidateRequiredLocation: String
    let salary: String?
    let description: String
    let tags: [String]
}

private enum SalaryParser {
    static func parse(_ text: String?) -> (Double?, Double?, String?) {
        guard let text, !text.isEmpty else { return (nil, nil, nil) }
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        let numbers = cleaned
            .split{ !$0.isNumber && $0 != "." }
            .compactMap { Double($0) }
        let currencySymbol = cleaned.first(where: { !$0.isNumber && !$0.isWhitespace })
        let currency = currencySymbol == "$" ? "USD" : nil
        switch numbers.count {
        case 0:
            return (nil, nil, currency)
        case 1:
            return (numbers[0], numbers[0], currency)
        default:
            return (numbers.first, numbers.last, currency)
        }
    }
}

private extension JobType {
    init(jobTypeString: String) {
        switch jobTypeString.lowercased() {
        case let value where value.contains("intern"):
            self = .internship
        case let value where value.contains("contract"):
            self = .contract
        case let value where value.contains("part"):
            self = .partTime
        default:
            self = .fullTime
        }
    }
}
