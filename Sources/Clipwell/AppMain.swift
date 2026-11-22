import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
@MainActor
private enum ClipwellApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}

private final class HistoryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = HistoryStore()
    private let session = PanelSession()
    private var statusItem: NSStatusItem!
    private var panel: HistoryPanel?
    private var eventMonitor: Any?
    private var outsideClickMonitor: Any?
    private lazy var hotKeys = GlobalHotKeys { [weak self] shortcut in
        self?.handle(shortcut)
    }
    private func makePanel() -> HistoryPanel {
        let panel = HistoryPanel(
            contentRect: NSRect(x: 0, y: 0, width: 428, height: 534),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        panel.title = "Clipwell Clipboard History"
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [
            .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .transient, .ignoresCycle
        ]
        panel.contentView = NSHostingView(rootView: HistoryView(
            store: store, session: session,
            dismiss: { [weak self] in self?.hidePanel() },
            quit: { NSApp.terminate(nil) }
        ))
        return panel
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "Clipwell")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Clipwell • Clipboard History"
            button.setAccessibilityLabel("Clipwell clipboard history")
            button.target = self
            button.action = #selector(statusItemPressed)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        store.start()
        session.unavailableShortcuts = hotKeys.register()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handlePanelKey(event) == true ? nil : event
        }
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(activeSpaceChanged),
                           name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(activeAppChanged),
                           name: NSWorkspace.didActivateApplicationNotification, object: nil)

        if !UserDefaults.standard.bool(forKey: "hasShownHistory") {
            DispatchQueue.main.async { [weak self] in self?.showPanel() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showPanel()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        removeOutsideClickMonitor()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        hotKeys.unregister()
        store.stop()
    }

    @objc private func statusItemPressed() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showStatusMenu()
        } else {
            togglePanel(anchorToButton: true)
        }
    }

    private func showStatusMenu() {
        hidePanel()
        let menu = NSMenu()
        let items: [(String, Selector)] = [
            ("Show History", #selector(showFromMenu)),
            (store.isPaused ? "Resume Capture" : "Pause Capture", #selector(changeCaptureState)),
            ("Quit Clipwell", #selector(quit))
        ]
        for (title, action) in items {
            if action == #selector(quit) { menu.addItem(.separator()) }
            menu.addItem(withTitle: title, action: action, keyEquivalent: "").target = self
        }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc private func showFromMenu() { showPanel(anchorToButton: true) }
    @objc private func changeCaptureState() { store.togglePause() }
    @objc private func quit() { NSApp.terminate(nil) }

    private func handle(_ shortcut: GlobalShortcut) {
        switch shortcut {
        case .showHistory: togglePanel(anchorToButton: false)
        case .copyFirst: copyRecent(at: 0)
        case .copySecond: copyRecent(at: 1)
        case .copyThird: copyRecent(at: 2)
        }
    }

    private func copyRecent(at index: Int) {
        store.poll()
        guard store.entries.indices.contains(index), store.copy(store.entries[index]) else {
            NSSound.beep()
            return
        }
        hidePanel()
    }

    private func togglePanel(anchorToButton: Bool) {
        if panel?.isVisible == true { hidePanel() }
        else { showPanel(anchorToButton: anchorToButton) }
    }

    private func showPanel(anchorToButton: Bool = false) {
        store.poll()
        let panel = self.panel ?? makePanel()
        self.panel = panel
        position(panel, anchorToButton: anchorToButton)
        // A nonactivating key panel borrows keyboard focus. Closing it returns
        // typing to the user's previous application, including in full screen.
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        session.reset()
        statusItem.button?.highlight(true)
        UserDefaults.standard.set(true, forKey: "hasShownHistory")
        if outsideClickMonitor == nil {
            outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] _ in
                self?.hidePanel()
            }
        }
    }

    private func hidePanel() {
        guard let panel, panel.isVisible else { return }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        removeOutsideClickMonitor()
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
    }

    private func position(_ panel: HistoryPanel, anchorToButton: Bool) {
        let button = statusItem.button
        let buttonWindow = button?.window
        let pointer = NSEvent.mouseLocation
        let pointerScreen = NSScreen.screens.first { $0.frame.contains(pointer) }
        guard let screen = pointerScreen ?? buttonWindow?.screen ?? NSScreen.main else { return }

        let visible = screen.visibleFrame
        let size = panel.frame.size
        var right = anchorToButton ? pointer.x + NSStatusBar.system.thickness / 2 : visible.maxX - 8
        var top = visible.maxY - 6
        if let button, let buttonWindow, buttonWindow.screen == screen {
            let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            // AppKit can initially expose a status window at the screen origin
            // while the menu bar is assigning its actual position.
            let menuBarHeight = max(NSStatusBar.system.thickness, screen.frame.maxY - visible.maxY)
            if screen.frame.intersects(anchor) && anchor.midY >= screen.frame.maxY - menuBarHeight {
                right = anchor.maxX
                top = min(top, anchor.minY - 5)
            }
        }
        let x = max(visible.minX + 8, min(right - size.width, visible.maxX - size.width - 8))
        let y = max(top, visible.minY + size.height + 6)
        panel.setFrameTopLeftPoint(NSPoint(x: x, y: y))
    }

    @objc private func activeSpaceChanged() { hidePanel() }

    @objc private func activeAppChanged(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app != NSRunningApplication.current else { return }
        hidePanel()
    }

    private func handlePanelKey(_ event: NSEvent) -> Bool {
        guard let panel, panel.isKeyWindow, event.window === panel,
              panel.attachedSheet == nil, NSApp.modalWindow == nil else { return false }
        let editor = panel.firstResponder as? NSTextView
        guard editor?.hasMarkedText() != true else { return false }
        let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
        if modifiers.isEmpty, Int(event.keyCode) == kVK_Escape {
            if !session.goBack() { hidePanel() }
            return true
        }
        guard session.screen == .history else { return false }
        if modifiers.isEmpty {
            switch Int(event.keyCode) {
            case kVK_UpArrow: session.moveSelection(-1)
            case kVK_DownArrow: session.moveSelection(1)
            case kVK_Return, kVK_ANSI_KeypadEnter: session.activateSelection()
            default: return false
            }
            return true
        }
        let key = event.charactersIgnoringModifiers?.lowercased()
        if modifiers == [.command, .shift], key == "z", let editor {
            editor.undoManager?.redo()
            return true
        }
        guard modifiers == .command else { return false }
        switch key {
        case "p": session.togglePinSelection()
        case "1": session.setFilter(false)
        case "2": session.setFilter(true)
        case "f": session.focusSearch()
        case "a" where editor != nil: editor?.selectAll(nil)
        case "x" where editor != nil: editor?.cut(nil)
        case "c" where editor != nil: editor?.copy(nil)
        case "v" where editor != nil: editor?.paste(nil)
        case "z" where editor != nil: editor?.undoManager?.undo()
        default: return false
        }
        return true
    }
}
