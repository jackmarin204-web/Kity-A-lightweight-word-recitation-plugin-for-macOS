import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment = AppEnvironment()
        environment?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment?.stop()
    }
}
