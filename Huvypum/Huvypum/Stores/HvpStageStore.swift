import Foundation
import Combine

final class HvpStageStore: ObservableObject {
    @Published var clips: [HvpClip] = []
    @Published var remarks: [HvpRemark] = []
    @Published var likes: [String: Bool] = [:]
    @Published var saves: [String: Bool] = [:]
    @Published var follows: [String: Bool] = [:]
    @Published var blocked: [String: Bool] = [:]
    @Published var hidden: [String: Bool] = [:]
    @Published var filterOn = true
    @Published var draft: HvpDraft?
    @Published var lastSavedId: String?

    private let defaults = UserDefaults.standard

    func load() {
        if let data = defaults.data(forKey: "hvp.clips"),
           let decoded = try? JSONDecoder().decode([HvpClip].self, from: data) {
            clips = decoded
        } else {
            clips = HvpCatalog.seed
        }
        if !clips.contains(where: { $0.id == "h00" }),
           let promo = HvpCatalog.seed.first(where: { $0.id == "h00" }) {
            clips.append(promo)
        }
        if let data = defaults.data(forKey: "hvp.remarks"),
           let decoded = try? JSONDecoder().decode([HvpRemark].self, from: data),
           !decoded.isEmpty {
            remarks = decoded
            let existing = Set(remarks.map(\.id))
            let extra = HvpCatalog.seedRemarks.filter { !existing.contains($0.id) }
            if !extra.isEmpty {
                remarks.append(contentsOf: extra)
            }
        } else {
            remarks = HvpCatalog.seedRemarks
        }
        likes = (defaults.dictionary(forKey: "hvp.likes") as? [String: Bool]) ?? [:]
        saves = (defaults.dictionary(forKey: "hvp.saves") as? [String: Bool]) ?? [:]
        follows = (defaults.dictionary(forKey: "hvp.follows") as? [String: Bool]) ?? [:]
        blocked = (defaults.dictionary(forKey: "hvp.blocked") as? [String: Bool]) ?? [:]
        hidden = (defaults.dictionary(forKey: "hvp.hidden") as? [String: Bool]) ?? [:]
        filterOn = defaults.object(forKey: HvpKeys.filterOn) as? Bool ?? true
        if let data = defaults.data(forKey: "hvp.draft") {
            draft = try? JSONDecoder().decode(HvpDraft.self, from: data)
        }
        lastSavedId = defaults.string(forKey: "hvp.lastSaved")
        persist()
    }

    func persist() {
        if let data = try? JSONEncoder().encode(clips) { defaults.set(data, forKey: "hvp.clips") }
        if let data = try? JSONEncoder().encode(remarks) { defaults.set(data, forKey: "hvp.remarks") }
        defaults.set(likes, forKey: "hvp.likes")
        defaults.set(saves, forKey: "hvp.saves")
        defaults.set(follows, forKey: "hvp.follows")
        defaults.set(blocked, forKey: "hvp.blocked")
        defaults.set(hidden, forKey: "hvp.hidden")
        defaults.set(filterOn, forKey: HvpKeys.filterOn)
        if let draft, let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: "hvp.draft")
        } else {
            defaults.removeObject(forKey: "hvp.draft")
        }
        defaults.set(lastSavedId, forKey: "hvp.lastSaved")
    }

    var visibleClips: [HvpClip] {
        let live = clips.filter { clip in
            hidden[clip.id] != true
                && blocked[clip.author] != true
                && (!filterOn || !HvpFilterLexicon.flagged(clip.title + " " + clip.caption))
        }
        return live.sorted { lhs, rhs in
            if lhs.isBoosted != rhs.isBoosted { return lhs.isBoosted && !rhs.isBoosted }
            return lhs.id > rhs.id
        }
    }

    func remarks(for clipId: String) -> [HvpRemark] {
        let all = remarks.filter { $0.clipId == clipId }
        if filterOn {
            return all.filter { !HvpFilterLexicon.flagged($0.text) }
        }
        return all
    }

    func saveClip(_ clip: HvpClip) {
        clips.removeAll { $0.id == clip.id }
        clips.insert(clip, at: 0)
        lastSavedId = clip.id
        draft = nil
        persist()
    }

    func saveDraft(_ value: HvpDraft) {
        draft = value
        persist()
    }

    func clearDraft() {
        draft = nil
        persist()
    }

    func addRemark(clipId: String, author: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        remarks.append(
            HvpRemark(
                id: "r\(Int(Date().timeIntervalSince1970 * 1000))",
                clipId: clipId,
                author: author,
                avatarAsset: "HvpAvatarYou",
                text: trimmed,
                createdAt: Date()
            )
        )
        persist()
    }

    func boost(id: String, hours: Int = 24) {
        if let idx = clips.firstIndex(where: { $0.id == id }) {
            clips[idx].boostUntil = Date().addingTimeInterval(TimeInterval(hours * 3600))
            persist()
        }
    }

    func report(id: String) {
        hidden[id] = true
        persist()
    }

    func block(name: String) {
        blocked[name] = true
        persist()
    }

    func deleteWork(id: String) {
        clips.removeAll { $0.id == id }
        remarks.removeAll { $0.clipId == id }
        HvpMediaIO.remove(id: id)
        if lastSavedId == id { lastSavedId = clips.first(where: { $0.mine })?.id }
        persist()
    }

    func eraseEverything() {
        for clip in clips where clip.mine {
            HvpMediaIO.remove(id: clip.id)
        }
        clips = HvpCatalog.seed
        remarks = HvpCatalog.seedRemarks
        likes = [:]
        saves = [:]
        follows = [:]
        blocked = [:]
        hidden = [:]
        filterOn = true
        draft = nil
        lastSavedId = nil
        persist()
        HvpMediaIO.eraseAll()
    }

    func clip(id: String) -> HvpClip? {
        clips.first { $0.id == id }
    }

    func myWorks() -> [HvpClip] {
        clips.filter { $0.mine }
    }

    func clips(inNight id: String) -> [HvpClip] {
        visibleClips.filter { $0.nightId == id }
    }

    func renameMine(to name: String) {
        let handle = HvpAppStore.handle(from: name)
        for idx in clips.indices where clips[idx].mine {
            clips[idx].author = name
            clips[idx].handle = handle
        }
        for idx in remarks.indices where remarks[idx].avatarAsset == "HvpAvatarYou" {
            remarks[idx].author = name
        }
        persist()
    }
}
