import Foundation

final class ExpenseStore {
    private(set) var expenses: [Expense] = [] {
        didSet { NotificationCenter.default.post(name: .expensesDidChange, object: self) }
    }

    private let fileURL: URL
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = support.appendingPathComponent("Financio", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.fileURL = folder.appendingPathComponent("expenses.json")
        }
        load()
    }

    var activeExpenses: [Expense] {
        expenses.filter(\.isActive)
    }

    var monthlyTotal: Double {
        activeExpenses.reduce(0) { $0 + $1.amount }
    }

    func total(for category: ExpenseCategory) -> Double {
        activeExpenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    func expenses(for category: ExpenseCategory?, includeInactive: Bool, query: String) -> [Expense] {
        var items = category.map { cat in expenses.filter { $0.category == cat } } ?? expenses
        if !includeInactive {
            items = items.filter(\.isActive)
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed)
                    || $0.notes.localizedCaseInsensitiveContains(trimmed)
                    || $0.category.title.localizedCaseInsensitiveContains(trimmed)
            }
        }
        return items.sorted {
            if $0.isActive != $1.isActive { return $0.isActive && !$1.isActive }
            if $0.amount != $1.amount { return $0.amount > $1.amount }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        save()
    }

    func update(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else { return }
        expenses[index] = expense
        save()
    }

    func delete(ids: Set<UUID>) {
        expenses.removeAll { ids.contains($0.id) }
        save()
    }

    func delete(_ expense: Expense) {
        delete(ids: [expense.id])
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            expenses = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            expenses = try decoder.decode([Expense].self, from: data)
        } catch {
            expenses = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(expenses)
            try data.write(to: fileURL, options: [.atomic])
        } catch {}
    }
}

extension Notification.Name {
    static let expensesDidChange = Notification.Name("expensesDidChange")
}
