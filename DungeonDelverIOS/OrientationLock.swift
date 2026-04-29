import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .landscape
    }
}

struct LandscapeOrientationRequester: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                requestLandscapeOrientation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    requestLandscapeOrientation()
                }
            }
    }

    private func requestLandscapeOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
            debugPrint("Failed to request landscape orientation: \(error.localizedDescription)")
        }

        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

extension View {
    func requestsLandscapeOrientation() -> some View {
        modifier(LandscapeOrientationRequester())
    }
}
