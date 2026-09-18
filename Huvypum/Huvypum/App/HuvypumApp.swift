import SwiftUI
import UIKit

@main
struct HuvypumApp: App {
    @UIApplicationDelegateAdaptor(HvpAppDelegate.self) var hvpDelegate
    @StateObject private var appStore = HvpAppStore()
    @StateObject private var stage = HvpStageStore()
    @StateObject private var store = HvpStoreManager()

    init() {
        if let url = URL(string: HvpAppCopy.privacyURL) {
            HvpPrivacyWarmup.ping(url)
        }
    }

    var body: some Scene {
        WindowGroup {
            HvpRootView()
                .environmentObject(appStore)
                .environmentObject(stage)
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

final class HvpAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
}
