import SwiftUI

struct HvpPreviewView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var store: HvpStoreManager
    let draft: HvpDraft
    @State private var savedId: String?
    @State private var error = ""
    @State private var goStore = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Preview")
                    .font(.largeTitle.weight(.bold))
                Image(uiImage: HvpCoverArt.resolved(draft.coverAsset))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(22)
                if let name = draft.fileName {
                    let url = HvpMediaIO.root.appendingPathComponent(name)
                    if FileManager.default.fileExists(atPath: url.path), draft.kind == .video {
                        HvpLoopPlayer(url: url, muted: false)
                            .frame(height: 240)
                            .cornerRadius(18)
                    }
                }
                Text(draft.title).font(.title2.weight(.bold))
                Text(draft.caption)
                HStack {
                    Text("This save spends")
                    Spacer()
                    Text("\(HvpAppCopy.saveCost) Spotlight")
                }
                HStack {
                    Text("Balance on this iPhone")
                    Spacer()
                    Text("\(store.spotlights)")
                }
                .foregroundColor(HvpPalette.mute)
                Text("Preview does not spend. Confirm writes a clip with video, liner note, and Board placement.")
                    .font(.footnote)
                    .foregroundColor(HvpPalette.mute)
                if !error.isEmpty {
                    Text(error).foregroundColor(HvpPalette.rose)
                }
                Button("Confirm and save") { confirm() }
                    .buttonStyle(HvpPrimaryButtonStyle())
                NavigationLink(destination: HvpStoreView(), isActive: $goStore) { EmptyView() }
                if let savedId {
                    NavigationLink(destination: HvpClipDetailView(clipId: savedId)) {
                        Text("Open saved clip")
                    }
                    .buttonStyle(HvpTealButtonStyle())
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Preview", displayMode: .inline)
    }

    private func confirm() {
        error = ""
        if store.spotlights < HvpAppCopy.saveCost {
            goStore = true
            return
        }
        guard store.spendSave() else {
            goStore = true
            return
        }
        let clip = HvpClip(
            id: draft.id,
            author: appStore.displayName,
            handle: HvpAppStore.handle(from: appStore.displayName),
            avatarAsset: "HvpAvatarYou",
            coverAsset: draft.coverAsset,
            title: draft.title,
            caption: draft.caption,
            category: draft.category,
            likes: 0,
            durationLabel: draft.durationLabel,
            nightId: draft.nightId,
            fileName: draft.fileName,
            kind: draft.kind,
            boostUntil: nil,
            mine: true
        )
        stage.saveClip(clip)
        savedId = clip.id
    }
}
