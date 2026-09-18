import SwiftUI

struct HvpClipDetailView: View {
    @EnvironmentObject private var stage: HvpStageStore
    let clipId: String
    @State private var more = false

    var body: some View {
        ScrollView {
            if let clip = stage.clip(id: clipId) {
                VStack(alignment: .leading, spacing: 14) {
                    Image(uiImage: HvpCoverArt.resolved(clip.coverAsset))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(22)

                    if let name = clip.fileName {
                        let url = HvpMediaIO.root.appendingPathComponent(name)
                        if FileManager.default.fileExists(atPath: url.path) {
                            if clip.kind == .audio {
                                HvpLoopPlayer(url: url, muted: false)
                                    .frame(height: 70)
                            } else if clip.kind == .video {
                                HvpLoopPlayer(url: url, muted: false)
                                    .frame(height: 420)
                                    .cornerRadius(22)
                            }
                        }
                    }

                    HStack {
                        HvpFaceView(asset: clip.avatarAsset, mine: clip.mine, author: clip.author, size: 44)
                        NavigationLink(destination: HvpCreatorView(name: clip.author)) {
                            VStack(alignment: .leading) {
                                Text(clip.author).font(.headline).foregroundColor(HvpPalette.ink)
                                Text(clip.handle).font(.caption).foregroundColor(HvpPalette.mute)
                            }
                        }
                        Spacer()
                    }

                    Text(clip.title).font(.title2.weight(.bold))
                    Text(clip.caption).foregroundColor(HvpPalette.mute)
                    Text(clip.category.rawValue)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(HvpPalette.violet.opacity(0.15))
                        .cornerRadius(8)

                    NavigationLink(destination: HvpCommentsView(clipId: clip.id)) {
                        Text("Comments")
                    }
                    .buttonStyle(HvpSecondaryButtonStyle())

                    if clip.mine {
                        Button("Hold on Board") {
                            stage.boost(id: clip.id)
                        }
                        .buttonStyle(HvpTealButtonStyle())
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            } else {
                Text("That clip is no longer here.")
                    .padding()
            }
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Clip", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: { more = true }) {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.bold))
                    .foregroundColor(HvpPalette.mute)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        )
        .sheet(isPresented: $more) {
            HvpClipMoreSheet(
                clipId: clipId,
                onReport: { stage.report(id: clipId) },
                onBlock: { name in stage.block(name: name) }
            )
        }
    }
}

struct HvpCommentsView: View {
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var appStore: HvpAppStore
    let clipId: String
    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Comments")
                    .font(.largeTitle.weight(.bold))
                Toggle("Filter off-topic notes", isOn: $stage.filterOn)
                    .onChange(of: stage.filterOn, perform: { _ in stage.persist() })

                ForEach(stage.remarks(for: clipId)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        HvpFaceView(asset: item.avatarAsset, author: item.author, size: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.author).font(.headline)
                            Text(item.text).foregroundColor(HvpPalette.mute)
                        }
                    }
                    .padding(12)
                    .background(HvpPalette.plate)
                    .cornerRadius(14)
                }

                HStack {
                    TextField("Write a note on the take", text: $draft)
                        .padding(12)
                        .background(HvpPalette.plate)
                        .cornerRadius(12)
                    Button("Send") {
                        stage.addRemark(clipId: clipId, author: appStore.displayName, text: draft)
                        draft = ""
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Comments", displayMode: .inline)
    }
}

struct HvpCreatorView: View {
    @EnvironmentObject private var stage: HvpStageStore
    let name: String

    var body: some View {
        ScrollView {
            let clips = stage.visibleClips.filter { $0.author == name }
            VStack(alignment: .leading, spacing: 14) {
                Text(name).font(.largeTitle.weight(.bold))
                Text("Performer on the board. Block hides their clips from your feed.")
                    .foregroundColor(HvpPalette.mute)
                Button(stage.follows[name] == true ? "Following" : "Follow") {
                    stage.follows[name] = !(stage.follows[name] ?? false)
                    stage.persist()
                }
                .buttonStyle(HvpSecondaryButtonStyle())
                Button("Block \(name)") { stage.block(name: name) }
                    .foregroundColor(HvpPalette.rose)
                ForEach(clips) { clip in
                    NavigationLink(destination: HvpClipDetailView(clipId: clip.id)) {
                        Image(uiImage: HvpCoverArt.resolved(clip.coverAsset))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(18)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Performer", displayMode: .inline)
    }
}
