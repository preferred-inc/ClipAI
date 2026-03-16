import Cocoa

final class FloatingPanel: NSPanel {

    var onClose: (() -> Void)?

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 52),
            styleMask: [.titled, .fullSizeContentView],
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
        self.animationBehavior = .none
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        // Upper-center of screen
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.midX - frame.width / 2
            let y = sf.midY + sf.height * 0.15
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func showWithAnimation() {
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }

    func dismissWithAnimation(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
            completion?()
        })
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismissWithAnimation { [weak self] in
                self?.onClose?()
            }
        } else {
            super.keyDown(with: event)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
