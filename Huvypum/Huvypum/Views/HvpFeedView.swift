import SwiftUI

struct HvpFeedView: View {
    @EnvironmentObject private var stage: HvpStageStore
    @State private var moreId: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HvpBoardHeader()
                HvpBoardFilterBar()
                HvpBoardPostBar()
                HvpDraftBanner()
                HvpNightStrip()
                ForEach(stage.visibleClips) { clip in
                    HvpBoardCard(clip: clip, moreId: $moreId)
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Board", displayMode: .inline)
        .sheet(item: Binding(
            get: { moreId.map { HvpSheetToken(id: $0) } },
            set: { moreId = $0?.id }
        )) { token in
            HvpClipMoreSheet(
                clipId: token.id,
                onReport: { stage.report(id: token.id) },
                onBlock: { name in stage.block(name: name) }
            )
        }
    }
}

struct HvpBoardHeader: View {
    @EnvironmentObject private var store: HvpStoreManager

    var body: some View {
        HStack {
            Text("Board")
                .font(.largeTitle.weight(.bold))
            Spacer()
            Text("\(store.spotlights)")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(HvpPalette.violet.opacity(0.14))
                .cornerRadius(12)
        }
    }
}

struct HvpBoardFilterBar: View {
    @EnvironmentObject private var stage: HvpStageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Filter off-topic notes", isOn: $stage.filterOn)
                .onChange(of: stage.filterOn, perform: { _ in stage.persist() })
            Text("Hides spam, promo bait, and off-topic clips from this board.")
                .font(.footnote)
                .foregroundColor(HvpPalette.mute)
        }
        .padding(14)
        .background(HvpPalette.plate)
        .cornerRadius(18)
    }
}

struct HvpBoardPostBar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your take")
                .font(.headline)
            Text("Attach a clip in Booth, write a liner note, and save it onto this board.")
                .font(.footnote)
                .foregroundColor(HvpPalette.mute)
            NavigationLink(destination: HvpBoothView()) {
                Text("Start a take")
            }
            .buttonStyle(HvpTealButtonStyle())
        }
        .padding(14)
        .background(HvpPalette.plate)
        .cornerRadius(18)
    }
}

struct HvpNightStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nights on the board")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HvpNightBook.nights) { night in
                        NavigationLink(destination: HvpNightDetailView(night: night)) {
                            VStack {
                                Image(uiImage: HvpCoverArt.resolved(night.coverAsset))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                Text(night.city)
                                    .font(.caption)
                                    .foregroundColor(HvpPalette.mute)
                                    .lineLimit(1)
                            }
                            .frame(width: 72)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct HvpDraftBanner: View {
    @EnvironmentObject private var stage: HvpStageStore

    var body: some View {
        if let draft = stage.draft {
            VStack(alignment: .leading, spacing: 8) {
                Text("Draft in Booth").font(.headline)
                Text(draft.title.isEmpty ? "Untitled take" : draft.title)
                    .foregroundColor(HvpPalette.mute)
                NavigationLink(destination: HvpBoothView()) {
                    Text("Resume Draft")
                }
                .buttonStyle(HvpTealButtonStyle())
            }
            .padding(14)
            .background(HvpPalette.plate)
            .cornerRadius(18)
        }
    }
}

struct HvpSheetToken: Identifiable {
    var id: String
}

struct HvpClipMoreSheet: View {
    @EnvironmentObject private var stage: HvpStageStore
    @Environment(\.presentationMode) private var presentation
    let clipId: String
    let onReport: () -> Void
    let onBlock: (String) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This clip")
                        .font(.largeTitle.weight(.bold))
                    if let clip = stage.clip(id: clipId) {
                        Text(clip.title)
                            .foregroundColor(HvpPalette.mute)

                        Button("Report") {
                            onReport()
                            presentation.wrappedValue.dismiss()
                        }
                        .buttonStyle(HvpSecondaryButtonStyle())

                        if !clip.mine {
                            Button("Block \(clip.author)") {
                                onBlock(clip.author)
                                presentation.wrappedValue.dismiss()
                            }
                            .buttonStyle(HvpSecondaryButtonStyle())
                        }

                        NavigationLink(destination: HvpGuidelinesPage()) {
                            Text("Community Guidelines")
                        }
                        .buttonStyle(HvpSecondaryButtonStyle())

                        Button("Contact") {
                            HvpAppCopy.openMail()
                        }
                        .buttonStyle(HvpSecondaryButtonStyle())
                    } else {
                        Text("That clip is no longer here.")
                            .foregroundColor(HvpPalette.mute)
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(HvpPalette.paper.ignoresSafeArea())
            .navigationBarTitle("More", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentation.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HvpBoardCard: View {
    @EnvironmentObject private var stage: HvpStageStore
    let clip: HvpClip
    @Binding var moreId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HvpBoardCardHeader(clip: clip, moreId: $moreId)
            NavigationLink(destination: HvpClipDetailView(clipId: clip.id)) {
                Image(uiImage: HvpCoverArt.resolved(clip.coverAsset))
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(22)
            }
            .buttonStyle(PlainButtonStyle())
            Text(clip.title)
                .font(.headline)
                .foregroundColor(HvpPalette.ink)
            Text(clip.caption)
                .foregroundColor(HvpPalette.ink)
            HvpBoardCardActions(clip: clip)
            HvpBoardCardNotes(clip: clip)
        }
        .padding(14)
        .background(HvpPalette.plate)
        .cornerRadius(22)
    }
}

struct HvpBoardCardHeader: View {
    let clip: HvpClip
    @Binding var moreId: String?

    var body: some View {
        HStack {
            HvpFaceView(asset: clip.avatarAsset, mine: clip.mine, author: clip.author, size: 36)
            NavigationLink(destination: HvpCreatorView(name: clip.author)) {
                VStack(alignment: .leading) {
                    Text(clip.author).font(.headline).foregroundColor(HvpPalette.ink)
                    Text(clip.handle).font(.caption).foregroundColor(HvpPalette.mute)
                }
            }
            Spacer()
            Button(action: { moreId = clip.id }) {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.bold))
                    .foregroundColor(HvpPalette.mute)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct HvpBoardCardActions: View {
    @EnvironmentObject private var stage: HvpStageStore
    let clip: HvpClip

    var body: some View {
        HStack {
            Button(stage.likes[clip.id] == true ? "Liked" : "Like") {
                stage.likes[clip.id] = !(stage.likes[clip.id] ?? false)
                stage.persist()
            }
            Button(stage.saves[clip.id] == true ? "Saved" : "Save") {
                stage.saves[clip.id] = !(stage.saves[clip.id] ?? false)
                stage.persist()
            }
            NavigationLink(destination: HvpCommentsView(clipId: clip.id)) {
                Text("Comments \(stage.remarks(for: clip.id).count)")
            }
            .fixedSize()
            Spacer()
            Text(clip.durationLabel).font(.caption).foregroundColor(HvpPalette.mute)
        }
        .foregroundColor(HvpPalette.violet)
    }
}

struct HvpBoardCardNotes: View {
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var appStore: HvpAppStore
    let clip: HvpClip
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stage.remarks(for: clip.id).suffix(2))) { item in
                HStack(alignment: .top, spacing: 8) {
                    HvpFaceView(asset: item.avatarAsset, author: item.author, size: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.author).font(.subheadline.weight(.semibold))
                        Text(item.text).font(.subheadline).foregroundColor(HvpPalette.mute)
                    }
                }
            }

            if stage.remarks(for: clip.id).isEmpty {
                Text("Be the first to note this take.")
                    .font(.footnote)
                    .foregroundColor(HvpPalette.mute)
            }

            HStack {
                TextField("Write a note on the take", text: $draft)
                    .padding(10)
                    .background(HvpPalette.paper)
                    .cornerRadius(12)
                Button("Send") {
                    stage.addRemark(clipId: clip.id, author: appStore.displayName, text: draft)
                    draft = ""
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .foregroundColor(HvpPalette.violet)
            }
        }
    }
}

