import UIKit
import UserNotifications

enum HvpPushNotificationManager {
    static func requestAfterATT() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
