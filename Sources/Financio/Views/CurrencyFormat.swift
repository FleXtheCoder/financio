import Foundation

enum CurrencyFormat {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        formatter.currencyCode = "EUR"
        return formatter
    }()

    static func string(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f €", value)
    }
}
