import Foundation

struct SalaryRange: Codable, Hashable {
    var minimum: Double
    var maximum: Double

    init(minimum: Double, maximum: Double) {
        self.minimum = minimum
        self.maximum = max(maximum, minimum)
    }

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let minValue = formatter.string(from: minimum as NSNumber) ?? "$0"
        let maxValue = formatter.string(from: maximum as NSNumber) ?? "$0"
        return "\(minValue) - \(maxValue)"
    }
}
