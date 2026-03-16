import Cocoa
import SwiftUI
import Carbon.HIToolbox

private var appDelegateInstance: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appDelegateInstance = self
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
        menu.addItem(withTitle: "History", action: #selector(openHistory), keyEquivalent: "h")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu
    }

    // MARK: - Global HotKey (Carbon)

    private func registerGlobalHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        let modifiers: UInt32 = UInt32(cmdKey | optionKey)
        let keyCode: UInt32 = 47 // period '.'

        var ref: EventHotKeyRef?
        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &ref)
        hotKeyRef = ref

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, inEvent, _ -> OSStatus in
            guard let inEvent = inEvent else { return OSStatus(eventNotHandledErr) }
            var hkID = EventHotKeyID()
            let err = GetEventParameter(inEvent,
                                        EventParamName(kEventParamDirectObject),
                                        EventParamType(typeEventHotKeyID),
                                        nil,
                                        MemoryLayout<EventHotKeyID>.size,
                                        nil,
                                        &hkID)
            if err == noErr && hkID.id == 1 {
                DispatchQueue.main.async {
                    appDelegateInstance?.togglePanel()
                }
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(),
                            handler, 1, &eventType, nil, nil)
    }

    // MARK: - Panel

    @objc func togglePanel() {
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

    @objc private func openHistory() {
        if let w = historyWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 450),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClipAI History"
        window.contentView = NSHostingView(rootView: HistoryView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        historyWindow = window
    }

    @objc private func openSettings() {
        if let w = settingsWindow, w.isVisible {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClipAI Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }
}
