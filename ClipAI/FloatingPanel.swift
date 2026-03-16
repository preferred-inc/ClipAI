import Cocoa

final class FloatingPanel: NSPanel {

    var onClose: (() -> Void)?

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 52),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
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
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false // Shadow is handled by SwiftUI

        // Spotlight-like: upper-center of screen
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.midX - frame.width / 2
            let y = sf.midY + sf.height * 0.15
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismiss()
        } else {
            super.keyDown(with: event)
        }
    }

    override func resignKey() {
        super.resignKey()
        dismiss()
    }

    private func dismiss() {
        close()
        onClose?()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
