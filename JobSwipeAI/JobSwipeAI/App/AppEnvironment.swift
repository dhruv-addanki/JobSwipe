import Foundation

/// Central place to wire up shared services and mocks.
final class AppEnvironment: ObservableObject {
    let jobAPI: JobAPI

    init(jobAPI: JobAPI = MockJobAPI()) {
        self.jobAPI = jobAPI
    }
}
