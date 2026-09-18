import Foundation
import AppTrackingTransparency

enum HvpATTManager {
    static func requestIfNeeded(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else {
                completion()
            }
        }
    }
}
