import Foundation
import Combine
import UIKit

final class HvpAppStore: ObservableObject {
    @Published var hasEntered: Bool
    @Published var displayName: String
    @Published var avatarImage: UIImage?
    @Published var openBoothOnEnter = false
    @Published var category: HvpCategory
    @Published var quality: String

    private let defaults = UserDefaults.standard

    init() {
        hasEntered = defaults.bool(forKey: HvpKeys.hasEntered)
        displayName = defaults.string(forKey: HvpKeys.displayName) ?? "You"
        category = HvpCategory(rawValue: defaults.string(forKey: HvpKeys.category) ?? "") ?? .indie
        quality = defaults.string(forKey: HvpKeys.quality) ?? "1080p"
        avatarImage = Self.loadAvatar()
    }

    func enterFromWelcome() {
        hasEntered = true
        openBoothOnEnter = true
        defaults.set(true, forKey: HvpKeys.hasEntered)
    }

    func enterQuietly() {
        hasEntered = true
        defaults.set(true, forKey: HvpKeys.hasEntered)
    }

    func leaveSession() {
        hasEntered = false
        defaults.set(false, forKey: HvpKeys.hasEntered)
    }

    func saveDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        displayName = trimmed.isEmpty ? "You" : trimmed
        defaults.set(displayName, forKey: HvpKeys.displayName)
    }

    static func handle(from name: String) -> String {
        let slug = name.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        let text = String(String.UnicodeScalarView(slug).prefix(18))
        return "@" + (text.isEmpty ? "you" : text)
    }

    func saveCategory(_ value: HvpCategory) {
        category = value
        defaults.set(value.rawValue, forKey: HvpKeys.category)
    }

    func saveQuality(_ value: String) {
        quality = value
        defaults.set(value, forKey: HvpKeys.quality)
    }

    func saveAvatar(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.86) {
            try? data.write(to: Self.avatarURL, options: .atomic)
            avatarImage = image
        }
    }

    func clearAvatar() {
        try? FileManager.default.removeItem(at: Self.avatarURL)
        avatarImage = nil
    }

    func promptLaunchPermissionsIfNeeded() {
        guard !defaults.bool(forKey: HvpKeys.didPromptLaunchPerms) else { return }
        defaults.set(true, forKey: HvpKeys.didPromptLaunchPerms)
        HvpATTManager.requestIfNeeded {
            HvpPushNotificationManager.requestAfterATT()
        }
    }

    func resetSessionFlags() {
        hasEntered = false
        displayName = "You"
        category = .indie
        quality = "1080p"
        clearAvatar()
        defaults.removeObject(forKey: HvpKeys.hasEntered)
        defaults.removeObject(forKey: HvpKeys.displayName)
        defaults.removeObject(forKey: HvpKeys.didPromptLaunchPerms)
        defaults.removeObject(forKey: HvpKeys.category)
        defaults.removeObject(forKey: HvpKeys.quality)
    }

    private static var supportDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("HvpClips", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static var avatarURL: URL {
        supportDir.appendingPathComponent("avatar.jpg")
    }

    private static func loadAvatar() -> UIImage? {
        let url = avatarURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
