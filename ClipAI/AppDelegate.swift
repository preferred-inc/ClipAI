import Cocoa
import SwiftUI
import Carbon.HIToolbox

private var appDelegateInstance: AppDelegate?

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel?
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
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
    }
}
