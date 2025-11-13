import Foundation

extension String {
    func strippingHTML() -> String {
        guard let data = data(using: .utf8) else { return self }
        let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributed?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? self
    }
}
