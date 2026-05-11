import AppKit
import ApplicationServices
import ParketCore

func checkAccessibility() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

func setupCrashSafety() {
    let restore: @convention(c) (Int32) -> Void = { _ in
        WorkspaceManager.shared.restoreAllWindows()
        exit(0)
    }
    signal(SIGTERM, restore)
    signal(SIGINT, restore)
    atexit {
        WorkspaceManager.shared.restoreAllWindows()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard checkAccessibility() else {
    fputs("parket: accessibility permission required\n", stderr)
    exit(1)
}

Config.load()
setupCrashSafety()

let statusBar = StatusBar.shared
let workspace = WorkspaceManager.shared
workspace.bootstrap()

let hotkeys = Hotkeys.shared
hotkeys.start()

let observer = WindowObserver.shared
observer.start()

NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification,
    object: nil, queue: .main
) { _ in
    WorkspaceManager.shared.handleScreenChange()
}

fputs("parket: running\n", stderr)
app.run()
