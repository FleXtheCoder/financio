import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = ExpenseStore()
        let controller = MainWindowController(store: store)
        mainController = controller
        NSApp.mainMenu = Self.buildMenu(target: controller)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private static func buildMenu(target: MainWindowController) -> NSMenu {
        let main = NSMenu()

        let appMenuItem = NSMenuItem()
        main.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Über Financio", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Financio beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileItem = NSMenuItem()
        main.addItem(fileItem)
        let fileMenu = NSMenu(title: "Ablage")
        fileItem.submenu = fileMenu
        let neu = fileMenu.addItem(withTitle: "Neuer Eintrag", action: #selector(MainWindowController.addExpense), keyEquivalent: "n")
        neu.target = target
        let edit = fileMenu.addItem(withTitle: "Bearbeiten", action: #selector(MainWindowController.editSelected), keyEquivalent: "e")
        edit.target = target
        let del = fileMenu.addItem(withTitle: "Löschen", action: #selector(MainWindowController.deleteSelected), keyEquivalent: "\u{8}")
        del.target = target

        let editMenuItem = NSMenuItem()
        main.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Bearbeiten")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Widerrufen", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Wiederholen", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Ausschneiden", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Kopieren", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Einfügen", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Alles auswählen", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        return main
    }
}

@main
enum FinancioMain {
    // NSApplication.delegate ist weak – starke Referenz halten
    private static let retainedDelegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = retainedDelegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
