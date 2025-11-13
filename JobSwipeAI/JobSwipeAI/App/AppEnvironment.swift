import Foundation

/// Central place to wire up shared services and toggle between mock/remote data sources.
@MainActor
final class AppEnvironment: ObservableObject {
    @Published private(set) var jobAPI: JobAPI
    @Published var useMockJobs: Bool {
        didSet { refreshJobAPI() }
    }
    @Published var remoteSearchTerm: String {
        didSet {
            remotiveAPI.updateDefaultSearchTerm(remoteSearchTerm)
        }
    }

    private let mockAPI = MockJobAPI()
    private let remotiveAPI: RemotiveJobAPI

    init(
        useMockJobs: Bool = true,
        remoteConfiguration: RemotiveJobAPIConfiguration = .default
    ) {
        self.remotiveAPI = RemotiveJobAPI(configuration: remoteConfiguration)
        self.useMockJobs = useMockJobs
        self.remoteSearchTerm = remoteConfiguration.defaultSearchTerm
        self.jobAPI = useMockJobs ? mockAPI : remotiveAPI
        self.remotiveAPI.updateDefaultSearchTerm(remoteConfiguration.defaultSearchTerm)
    }

    var jobAPISourceID: ObjectIdentifier {
        ObjectIdentifier(jobAPI)
    }

    var currentJobProviderName: String {
        useMockJobs ? "Mock dataset" : remotiveAPI.providerName
    }

    private func refreshJobAPI() {
        jobAPI = useMockJobs ? mockAPI : remotiveAPI
    }
}
