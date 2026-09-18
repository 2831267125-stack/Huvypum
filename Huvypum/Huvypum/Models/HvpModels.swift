import Foundation
import UIKit

enum HvpMediaKind: String, Codable {
    case video
    case audio
    case photo
}

enum HvpCategory: String, Codable, CaseIterable, Identifiable {
    case indie = "Indie"
    case jazz = "Jazz"
    case electronic = "Electronic"
    case groove = "Groove"
    case folk = "Folk"
    case brass = "Brass"
    var id: String { rawValue }
}

struct HvpClip: Identifiable, Codable, Equatable {
    var id: String
    var author: String
    var handle: String
    var avatarAsset: String
    var coverAsset: String
    var title: String
    var caption: String
    var category: HvpCategory
    var likes: Int
    var durationLabel: String
    var nightId: String
    var fileName: String?
    var kind: HvpMediaKind
    var boostUntil: Date?
    var mine: Bool

    var isBoosted: Bool {
        guard let boostUntil else { return false }
        return boostUntil > Date()
    }
}

struct HvpRemark: Identifiable, Codable, Equatable {
    var id: String
    var clipId: String
    var author: String
    var avatarAsset: String
    var text: String
    var createdAt: Date
}

struct HvpNight: Identifiable, Codable, Equatable {
    var id: String
    var venue: String
    var city: String
    var bill: String
    var blurb: String
    var coverAsset: String
    var doors: String
    var capacity: Int
}

struct HvpCreditEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var packKey: String
    var transactionId: String
    var granted: Int
}

struct HvpDraft: Codable, Equatable {
    var id: String
    var nightId: String
    var category: HvpCategory
    var title: String
    var caption: String
    var coverAsset: String
    var fileName: String?
    var kind: HvpMediaKind
    var durationLabel: String
    var step: String
}
