import Foundation
import SwiftData

@Model
final class ResumeDocument {
    @Attribute(.unique) var id: UUID
    var rawText: String
    var lastUpdated: Date

    init(id: UUID = UUID(), rawText: String = "", lastUpdated: Date = .now) {
        self.id = id
        self.rawText = rawText
        self.lastUpdated = lastUpdated
    }
}
