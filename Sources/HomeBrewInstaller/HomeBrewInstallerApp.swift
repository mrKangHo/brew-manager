import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)

        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard let window = NSApp.windows.first else { return }
            Self.removeSidebarToggle(from: window)
        }
    }

    private static func removeSidebarToggle(from window: NSWindow) {
        guard let toolbar = window.toolbar else { return }
        if let index = toolbar.items.firstIndex(where: {
            $0.itemIdentifier == .toggleSidebar || $0.itemIdentifier.rawValue.contains("toggleSidebar")
        }) {
            toolbar.removeItem(at: index)
        }
    }
}

@main
struct HomeBrewInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .toolbar(removing: .sidebarToggle)
        }
        .windowResizability(.contentSize)
    }
}
