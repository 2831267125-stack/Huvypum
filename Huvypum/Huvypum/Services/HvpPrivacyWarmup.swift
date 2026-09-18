import Foundation

enum HvpPrivacyWarmup {
    static func ping(_ url: URL) {
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }
}
