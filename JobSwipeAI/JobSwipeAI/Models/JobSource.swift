import Foundation

enum JobSource: Equatable, Hashable, Codable {
    case mock
    case api(name: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case name
    }

    private enum SourceType: String, Codable {
        case mock
        case api
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SourceType.self, forKey: .type)
        switch type {
        case .mock:
            self = .mock
        case .api:
            let name = try container.decode(String.self, forKey: .name)
            self = .api(name: name)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mock:
            try container.encode(SourceType.mock, forKey: .type)
        case .api(let name):
            try container.encode(SourceType.api, forKey: .type)
            try container.encode(name, forKey: .name)
        }
    }
}
