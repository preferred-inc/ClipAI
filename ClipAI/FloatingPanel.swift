import Cocoa

final class FloatingPanel: NSPanel {

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 48),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        self.contentView = contentView
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.animationBehavior = .utilityWindow
        self.backgroundColor = .clear
        self.hasShadow = true

        // Spotlight-like position: upper-center
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.midX - frame.width / 2
            let y = sf.midY + sf.height * 0.15
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { close() }
        else { super.keyDown(with: event) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
