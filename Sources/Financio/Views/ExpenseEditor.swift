import AppKit

enum ExpenseEditor {
    @discardableResult
    static func present(on window: NSWindow?, title: String, expense: Expense) -> Expense? {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = title
        let view = EditorView(expense: expense)
        panel.contentView = view
        if let window {
            let origin = NSPoint(
                x: window.frame.midX - panel.frame.width / 2,
                y: window.frame.midY - panel.frame.height / 2
            )
            panel.setFrameOrigin(origin)
        } else {
            panel.center()
        }

        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: nil
        ) { _ in
            NSApp.stopModal()
        }
        NSApp.runModal(for: panel)
        NotificationCenter.default.removeObserver(observer)
        panel.orderOut(nil)
        return view.savedExpense
    }
}

private final class EditorView: NSView {
    private let nameField = NSTextField(string: "")
    private let amountField = NSTextField(string: "")
    private let categoryPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let dayStepper = NSStepper()
    private let dayLabel = NSTextField(labelWithString: "")
    private let activeCheckbox = NSButton(checkboxWithTitle: "Aktiv", target: nil, action: nil)
    private let notesField = NSTextField(string: "")
    private let original: Expense

    private(set) var savedExpense: Expense?
    private var billingDay = 1

    init(expense: Expense) {
        self.original = expense
        super.init(frame: NSRect(x: 0, y: 0, width: 400, height: 340))
        wantsLayer = true
        buildUI()
        populate(expense)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        func labeled(_ title: String, _ control: NSView) -> NSStackView {
            let label = NSTextField(labelWithString: title)
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabelColor
            let row = NSStackView(views: [label, control])
            row.orientation = .vertical
            row.alignment = .leading
            row.spacing = 4
            control.translatesAutoresizingMaskIntoConstraints = false
            control.widthAnchor.constraint(equalToConstant: 360).isActive = true
            return row
        }

        nameField.placeholderString = "z. B. Netflix, Auto-Kredit"
        amountField.placeholderString = "0,00"

        for category in ExpenseCategory.allCases {
            categoryPopup.addItem(withTitle: category.title)
            categoryPopup.lastItem?.representedObject = category.rawValue
        }

        dayStepper.minValue = 1
        dayStepper.maxValue = 31
        dayStepper.increment = 1
        dayStepper.target = self
        dayStepper.action = #selector(dayChanged)
        dayStepper.valueWraps = false
        let dayRow = NSStackView(views: [dayLabel, dayStepper])
        dayRow.orientation = .horizontal
        dayRow.spacing = 8

        notesField.placeholderString = "Notiz (optional)"

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        let cancel = NSButton(title: "Abbrechen", target: self, action: #selector(cancel))
        let save = NSButton(title: "Sichern", target: self, action: #selector(save))
        save.keyEquivalent = "\r"
        cancel.keyEquivalent = "\u{1b}"
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        buttons.addArrangedSubview(spacer)
        buttons.addArrangedSubview(cancel)
        buttons.addArrangedSubview(save)
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.widthAnchor.constraint(equalToConstant: 360).isActive = true

        stack.addArrangedSubview(labeled("Name", nameField))
        stack.addArrangedSubview(labeled("Betrag (€)", amountField))
        stack.addArrangedSubview(labeled("Kategorie", categoryPopup))
        stack.addArrangedSubview(labeled("Abbuchungstag", dayRow))
        stack.addArrangedSubview(activeCheckbox)
        stack.addArrangedSubview(labeled("Notiz", notesField))
        stack.addArrangedSubview(buttons)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func populate(_ expense: Expense) {
        nameField.stringValue = expense.name
        amountField.stringValue = expense.amount == 0
            ? ""
            : String(format: "%.2f", expense.amount).replacingOccurrences(of: ".", with: ",")
        if let index = ExpenseCategory.allCases.firstIndex(of: expense.category) {
            categoryPopup.selectItem(at: index)
        }
        billingDay = expense.billingDay
        dayStepper.integerValue = expense.billingDay
        updateDayLabel()
        activeCheckbox.state = expense.isActive ? .on : .off
        notesField.stringValue = expense.notes
    }

    private func updateDayLabel() {
        dayLabel.stringValue = "\(billingDay)."
    }

    @objc private func dayChanged() {
        billingDay = dayStepper.integerValue
        updateDayLabel()
    }

    @objc private func cancel() {
        savedExpense = nil
        NSApp.stopModal()
    }

    @objc private func save() {
        let cleanedName = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountRaw = amountField.stringValue
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty, let amount = Double(amountRaw), amount >= 0 else {
            NSSound.beep()
            return
        }
        let raw = categoryPopup.selectedItem?.representedObject as? String ?? ExpenseCategory.subscription.rawValue
        let category = ExpenseCategory(rawValue: raw) ?? .subscription
        var expense = original
        expense.name = cleanedName
        expense.amount = amount
        expense.category = category
        expense.billingDay = billingDay
        expense.notes = notesField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.isActive = activeCheckbox.state == .on
        savedExpense = expense
        NSApp.stopModal()
    }
}
