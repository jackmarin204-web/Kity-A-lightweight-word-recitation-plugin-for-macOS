import AppKit

struct MenuBarIconConfiguration {
    static let `default` = MenuBarIconConfiguration(
        size: NSSize(width: 22, height: 22),
        isTemplate: false
    )

    let size: NSSize
    let isTemplate: Bool
}

final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.squareLength
    )
    private let pauseItem = NSMenuItem()
    private let isPaused: () -> Bool
    private let togglePause: () -> Void

    init(isPaused: @escaping () -> Bool, togglePause: @escaping () -> Void) {
        self.isPaused = isPaused
        self.togglePause = togglePause
        super.init()
        configureStatusItem()
    }

    func updatePausedState() {
        pauseItem.title = isPaused() ? "Resume" : "Pause"
    }

    func setAvailable(_ available: Bool) {
        pauseItem.isEnabled = available
        statusItem.button?.contentTintColor = available
            ? .controlTextColor
            : .disabledControlTextColor
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            let image = NSImage(named: "KityMenuBarCat")
            let configuration = MenuBarIconConfiguration.default
            image?.size = configuration.size
            image?.accessibilityDescription = "Kity"
            image?.isTemplate = configuration.isTemplate
            button.image = image
        }

        let menu = NSMenu()
        pauseItem.target = self
        pauseItem.action = #selector(togglePauseSelected)
        menu.addItem(pauseItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Kity",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        updatePausedState()
    }

    @objc private func togglePauseSelected() {
        togglePause()
        updatePausedState()
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: self
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
