import Foundation

// Central place to wire up shared services and toggle between mock/remote data sources.
@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var jobAPI: JobAPI
    @Published var useMockJobs: Bool {
        didSet { refreshJobAPI() }
    }
    @Published var remoteSearchTerm: String {
        didSet {
            adzunaAPI.updateDefaultSearchTerm(remoteSearchTerm)
        }
    }

    private let mockAPI = MockJobAPI()
    private let adzunaAPI: AdzunaJobAPI

    init(
        useMockJobs: Bool = true,
        adzunaConfiguration: AdzunaJobAPIConfiguration = .default
    ) {
        self.adzunaAPI = AdzunaJobAPI(configuration: adzunaConfiguration)
        let shouldUseMock = useMockJobs || !adzunaConfiguration.isConfigured
        self.useMockJobs = shouldUseMock
        self.remoteSearchTerm = adzunaConfiguration.defaultSearchTerm
        self.jobAPI = shouldUseMock ? mockAPI : adzunaAPI
        self.adzunaAPI.updateDefaultSearchTerm(adzunaConfiguration.defaultSearchTerm)
    }

    var jobAPISourceID: ObjectIdentifier {
        ObjectIdentifier(jobAPI)
    }

    var currentJobProviderName: String {
        (jobAPI as? MockJobAPI) != nil ? "Mock dataset" : adzunaAPI.providerName
    }

    var isRemoteProviderConfigured: Bool {
        adzunaAPI.isConfigured
    }

    private func refreshJobAPI() {
        if useMockJobs {
            jobAPI = mockAPI
        } else if adzunaAPI.isConfigured {
            jobAPI = adzunaAPI
        } else {
            jobAPI = mockAPI
            if !useMockJobs {
                useMockJobs = true
            }
        }
    }
}
