import AppKit

final class MainWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private let store: ExpenseStore
    private var filtered: [Expense] = []
    private var selectedCategory: ExpenseCategory?
    private var showInactive = false
    private var query = ""

    private let categoryTable = NSTableView()
    private let expenseTable = NSTableView()
    private let totalLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let chipAbos = NSTextField(labelWithString: "")
    private let chipFin = NSTextField(labelWithString: "")
    private let chipOther = NSTextField(labelWithString: "")
    private let searchField = NSSearchField()
    private let emptyLabel = NSTextField(labelWithString: "")

    private let categories: [ExpenseCategory?] = [nil] + ExpenseCategory.allCases.map { Optional($0) }

    init(store: ExpenseStore) {
        self.store = store
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Financio"
        window.minSize = NSSize(width: 700, height: 420)
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.contentView = buildContent()
        window.toolbar = buildToolbar()
        reload()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: .expensesDidChange,
            object: store
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func buildContent() -> NSView {
        let root = NSView()
        root.wantsLayer = true

        let sidebar = makeScroll(for: categoryTable)
        configureCategoryTable()

        let summary = makeSummary()
        let listScroll = makeScroll(for: expenseTable)
        configureExpenseTable()

        emptyLabel.stringValue = "Keine Einträge"
        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.isHidden = true

        let detail = NSStackView(views: [summary, listScroll])
        detail.orientation = .vertical
        detail.spacing = 12
        detail.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        detail.translatesAutoresizingMaskIntoConstraints = false
        listScroll.setContentHuggingPriority(.defaultLow, for: .vertical)

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(sidebar)
        split.addArrangedSubview(detail)
        split.setHoldingPriority(.defaultHigh, forSubviewAt: 0)
        split.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(split)
        root.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            split.topAnchor.constraint(equalTo: root.topAnchor),
            split.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            split.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 180),
            emptyLabel.centerXAnchor.constraint(equalTo: listScroll.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: listScroll.centerYAnchor)
        ])

        return root
    }

    private func makeSummary() -> NSView {
        totalLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        totalLabel.textColor = .labelColor
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.stringValue = "Monatliche Kosten"

        for chip in [chipAbos, chipFin, chipOther] {
            chip.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            chip.textColor = .secondaryLabelColor
        }

        let chips = NSStackView(views: [chipAbos, chipFin, chipOther])
        chips.orientation = .horizontal
        chips.distribution = .fillEqually
        chips.spacing = 16

        let header = NSStackView(views: [subtitleLabel, totalLabel, chips])
        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = 6
        header.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        header.wantsLayer = true
        header.layer?.cornerRadius = 12
        header.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let box = NSBox()
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.contentViewMargins = .zero
        box.contentView = header
        box.fillColor = .controlBackgroundColor
        box.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 110).isActive = true
        return box
    }

    private func makeScroll(for table: NSTableView) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.documentView = table
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }

    private func configureCategoryTable() {
        categoryTable.headerView = nil
        categoryTable.allowsEmptySelection = false
        categoryTable.allowsMultipleSelection = false
        categoryTable.style = .sourceList
        categoryTable.rowSizeStyle = .medium
        categoryTable.addTableColumn(NSTableColumn(identifier: .init("cat")))
        categoryTable.dataSource = self
        categoryTable.delegate = self
        categoryTable.target = self
        categoryTable.action = #selector(categoryClicked)
        categoryTable.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    private func configureExpenseTable() {
        expenseTable.headerView = nil
        expenseTable.allowsMultipleSelection = true
        expenseTable.usesAlternatingRowBackgroundColors = true
        expenseTable.style = .inset
        expenseTable.rowHeight = 44
        expenseTable.doubleAction = #selector(editSelected)
        expenseTable.target = self
        let column = NSTableColumn(identifier: .init("expense"))
        column.width = 600
        expenseTable.addTableColumn(column)
        expenseTable.dataSource = self
        expenseTable.delegate = self
        expenseTable.menu = makeContextMenu()
    }

    private func buildToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.delegate = ToolbarDelegate.shared
        ToolbarDelegate.shared.host = self
        searchField.placeholderString = "Suchen"
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchChanged)
        return toolbar
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Bearbeiten", action: #selector(editSelected), keyEquivalent: "")
        menu.addItem(withTitle: "Aktiv umschalten", action: #selector(toggleActive), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Löschen", action: #selector(deleteSelected), keyEquivalent: "")
        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc func reload() {
        filtered = store.expenses(for: selectedCategory, includeInactive: showInactive, query: query)
        categoryTable.reloadData()
        expenseTable.reloadData()
        updateSummary()
        emptyLabel.isHidden = !filtered.isEmpty
        emptyLabel.stringValue = query.isEmpty ? "Keine Einträge – mit + hinzufügen" : "Keine Treffer"
        // Keep sidebar appearance in sync with system light/dark
        if let summary = window?.contentView?.subviews.first as? NSSplitView,
           let detail = summary.arrangedSubviews.last as? NSStackView,
           let box = detail.arrangedSubviews.first as? NSBox {
            box.fillColor = .controlBackgroundColor
            box.contentView?.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    private func updateSummary() {
        totalLabel.stringValue = CurrencyFormat.string(from: store.monthlyTotal)
        chipAbos.stringValue = "Abos  \(CurrencyFormat.string(from: store.total(for: .subscription)))"
        chipFin.stringValue = "Finanzierungen  \(CurrencyFormat.string(from: store.total(for: .financing)))"
        chipOther.stringValue = "Sonstiges  \(CurrencyFormat.string(from: store.total(for: .other)))"
        subtitleLabel.stringValue = "Monatliche Kosten · \(store.activeExpenses.count) aktiv"
    }

    @objc private func categoryClicked() {
        let row = categoryTable.selectedRow
        guard row >= 0, row < categories.count else { return }
        selectedCategory = categories[row]
        reload()
    }

    @objc func addExpense() {
        guard let created = ExpenseEditor.present(on: window, title: "Neue Kosten", expense: Expense()) else { return }
        store.add(created)
    }

    @objc func editSelected() {
        let row = expenseTable.clickedRow >= 0 ? expenseTable.clickedRow : expenseTable.selectedRow
        guard row >= 0, row < filtered.count else { return }
        guard let updated = ExpenseEditor.present(on: window, title: "Bearbeiten", expense: filtered[row]) else { return }
        store.update(updated)
    }

    @objc func toggleActive() {
        let row = expenseTable.clickedRow >= 0 ? expenseTable.clickedRow : expenseTable.selectedRow
        guard row >= 0, row < filtered.count else { return }
        var expense = filtered[row]
        expense.isActive.toggle()
        store.update(expense)
    }

    @objc func deleteSelected() {
        var rows = expenseTable.selectedRowIndexes
        if rows.isEmpty, expenseTable.clickedRow >= 0 {
            rows = IndexSet(integer: expenseTable.clickedRow)
        }
        let ids = Set(rows.compactMap { filtered.indices.contains($0) ? filtered[$0].id : nil })
        guard !ids.isEmpty else { return }
        store.delete(ids: ids)
    }

    @objc func toggleInactive(_ sender: NSButton) {
        showInactive = sender.state == .on
        sender.toolTip = showInactive ? "Inaktive ausblenden" : "Inaktive anzeigen"
        reload()
    }

    @objc func searchChanged() {
        query = searchField.stringValue
        reload()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField === searchField else { return }
        query = searchField.stringValue
        reload()
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === categoryTable { return categories.count }
        return filtered.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView === categoryTable {
            let cell = NSTableCellView()
            let field = NSTextField(labelWithString: "")
            field.isEditable = false
            field.drawsBackground = false
            field.isBordered = false
            field.translatesAutoresizingMaskIntoConstraints = false
            let category = categories[row]
            field.stringValue = category?.title ?? "Alle"
            cell.addSubview(field)
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                field.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
            cell.textField = field
            return cell
        }

        let expense = filtered[row]
        let cell = NSTableCellView()
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: expense.category.systemImage, accessibilityDescription: nil)
        icon.contentTintColor = .secondaryLabelColor
        icon.translatesAutoresizingMaskIntoConstraints = false

        let name = NSTextField(labelWithString: expense.name)
        name.font = .systemFont(ofSize: 13, weight: .medium)
        name.textColor = expense.isActive ? .labelColor : .secondaryLabelColor
        name.lineBreakMode = .byTruncatingTail

        var meta = "\(expense.category.title) · am \(expense.billingDay)."
        if !expense.notes.isEmpty { meta += " · \(expense.notes)" }
        let detail = NSTextField(labelWithString: meta)
        detail.font = .systemFont(ofSize: 11)
        detail.textColor = .tertiaryLabelColor
        detail.lineBreakMode = .byTruncatingTail

        let textStack = NSStackView(views: [name, detail])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let amount = NSTextField(labelWithString: CurrencyFormat.string(from: expense.amount))
        amount.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        amount.textColor = expense.isActive ? .labelColor : .secondaryLabelColor
        amount.alignment = .right
        amount.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(icon)
        cell.addSubview(textStack)
        cell.addSubview(amount)
        cell.alphaValue = expense.isActive ? 1 : 0.55

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: amount.leadingAnchor, constant: -12),
            amount.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -12),
            amount.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            amount.widthAnchor.constraint(greaterThanOrEqualToConstant: 90)
        ])
        return cell
    }

    var toolbarSearchField: NSSearchField { searchField }
}

// MARK: - Toolbar

private final class ToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = ToolbarDelegate()
    weak var host: MainWindowController?

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .search, .toggleInactive, .add]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleInactive, .flexibleSpace, .search, .add]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .add:
            let item = NSToolbarItem(itemIdentifier: .add)
            item.label = "Neu"
            item.paletteLabel = "Neu"
            item.toolTip = "Monatliche Kosten hinzufügen (⌘N)"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Neu")
            item.target = host
            item.action = #selector(MainWindowController.addExpense)
            item.isBordered = true
            return item
        case .toggleInactive:
            let item = NSToolbarItem(itemIdentifier: .toggleInactive)
            item.label = "Inaktive"
            item.paletteLabel = "Inaktive"
            let button = NSButton(
                image: NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Inaktive") ?? NSImage(),
                target: host,
                action: #selector(MainWindowController.toggleInactive(_:))
            )
            button.setButtonType(.pushOnPushOff)
            button.bezelStyle = .texturedRounded
            button.isBordered = true
            button.toolTip = "Inaktive anzeigen"
            item.view = button
            return item
        case .search:
            let item = NSSearchToolbarItem(itemIdentifier: .search)
            item.searchField = host?.toolbarSearchField ?? NSSearchField()
            item.toolTip = "Suchen"
            item.resignsFirstResponderWithCancel = true
            return item
        default:
            return nil
        }
    }
}

private extension NSToolbarItem.Identifier {
    static let add = NSToolbarItem.Identifier("Add")
    static let toggleInactive = NSToolbarItem.Identifier("ToggleInactive")
    static let search = NSToolbarItem.Identifier("Search")
}
