import Foundation
import SwiftData

@MainActor
enum ModelContainerProvider {
    static func shared(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            ResumeDocument.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
}
