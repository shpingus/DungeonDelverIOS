import SwiftUI

@main
struct DungeonDelverIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBarHidden(true)
                .requestsLandscapeOrientation()
        }
    }
}
