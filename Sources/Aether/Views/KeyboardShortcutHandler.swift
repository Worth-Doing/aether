import SwiftUI
import AppKit

struct KeyboardShortcutHandler: NSViewRepresentable {
    let onNewTab: () -> Void
    let onCloseTab: () -> Void
    let onReopenTab: () -> Void
    let onCommandBar: () -> Void
    let onToggleSidebar: () -> Void
    let onSplitH: () -> Void
    let onSplitV: () -> Void
    let onSettings: () -> Void
    let onBookmark: () -> Void
    let commandBarVisible: Bool
    let onCommandBarUp: () -> Void
    let onCommandBarDown: () -> Void
    let onCommandBarDismiss: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.handler = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        var parent: KeyboardShortcutHandler

        init(parent: KeyboardShortcutHandler) {
            self.parent = parent
        }

        func handleKeyDown(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyCode = event.keyCode

            // Command bar navigation
            if parent.commandBarVisible {
                if keyCode == 125 { // Down arrow
                    parent.onCommandBarDown()
                    return true
                }
                if keyCode == 126 { // Up arrow
                    parent.onCommandBarUp()
                    return true
                }
                if keyCode == 53 { // Escape
                    parent.onCommandBarDismiss()
                    return true
                }
            }

            // Cmd+T — New tab
            if flags == .command && keyCode == 17 {
                parent.onNewTab()
                return true
            }

            // Cmd+W — Close tab
            if flags == .command && keyCode == 13 {
                parent.onCloseTab()
                return true
            }

            // Cmd+Shift+T — Reopen tab
            if flags == [.command, .shift] && keyCode == 17 {
                parent.onReopenTab()
                return true
            }

            // Cmd+K or Cmd+L — Command bar
            if flags == .command && (keyCode == 40 || keyCode == 37) {
                parent.onCommandBar()
                return true
            }

            // Cmd+S (sidebar toggle)
            if flags == [.command, .shift] && keyCode == 1 {
                parent.onToggleSidebar()
                return true
            }

            // Cmd+\ — Split horizontal
            if flags == .command && keyCode == 42 {
                parent.onSplitH()
                return true
            }

            // Cmd+Shift+\ — Split vertical
            if flags == [.command, .shift] && keyCode == 42 {
                parent.onSplitV()
                return true
            }

            // Cmd+D — Bookmark
            if flags == .command && keyCode == 2 {
                parent.onBookmark()
                return true
            }

            // Cmd+, — Settings
            if flags == .command && keyCode == 43 {
                parent.onSettings()
                return true
            }

            return false
        }
    }
}

class KeyCaptureView: NSView {
    var handler: KeyboardShortcutHandler.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if handler?.handleKeyDown(event) != true {
            super.keyDown(with: event)
        }
    }
}
