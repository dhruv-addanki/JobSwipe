import SwiftUI
import SwiftData

@main
struct JobSwipeAIApp: App {
    @StateObject private var environment = AppEnvironment()
    private let modelContainer: ModelContainer

    init() {
        self.modelContainer = ModelContainerProvider.shared()
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(environment)
        }
        .modelContainer(modelContainer)
    }
}
