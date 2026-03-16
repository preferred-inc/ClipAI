import Cocoa
import SwiftUI
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        registerGlobalHotKey()
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "ClipAI")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Show  ⌘⌥.", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu
    }

    // MARK: - Global HotKey

    private func registerGlobalHotKey() {
        // Use NSEvent global monitor — works without Accessibility if app is signed
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌘⇧. (Cmd+Shift+Period)
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 47 {
                DispatchQueue.main.async {
                    self?.togglePanel()
                }
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 47 {
                DispatchQueue.main.async {
                    self?.togglePanel()
                }
                return nil
            }
            return event
        }
    }

    // MARK: - Panel

    @objc private func togglePanel() {
        if let existing = panel, existing.isVisible {
            existing.dismissWithAnimation { [weak self] in
                self?.panel = nil
            }
            return
        }

        let clipboardText = NSPasteboard.general.string(forType: .string) ?? ""

        let contentView = ContentView(clipboardText: clipboardText, onClose: { [weak self] in
            self?.panel?.dismissWithAnimation {
                self?.panel = nil
            }
        })

        let hostingView = NSHostingView(rootView: contentView)

        let newPanel = FloatingPanel(contentView: hostingView)
        newPanel.onClose = { [weak self] in
            self?.panel = nil
        }
        newPanel.showWithAnimation()
        NSApp.activate(ignoringOtherApps: true)
        self.panel = newPanel
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }
}
