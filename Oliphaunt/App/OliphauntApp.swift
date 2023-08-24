import SwiftUI

@main
struct OliphauntApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
//            ContentView()
            ImageGalleryView_Previews.previews
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
    }
}
