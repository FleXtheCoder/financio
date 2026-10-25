import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case subscription
    case financing
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscription: return "Abo"
        case .financing: return "Finanzierung"
        case .other: return "Sonstiges"
        }
    }

    var systemImage: String {
        switch self {
        case .subscription: return "repeat"
        case .financing: return "creditcard"
        case .other: return "tag"
        }
    }
}

struct Expense: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var billingDay: Int
    var notes: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Double = 0,
        category: ExpenseCategory = .subscription,
        billingDay: Int = 1,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.billingDay = min(max(billingDay, 1), 31)
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
