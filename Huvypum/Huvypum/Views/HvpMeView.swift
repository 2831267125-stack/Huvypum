import SwiftUI

struct HvpMeView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var store: HvpStoreManager
    @State private var name = ""
    @State private var showPhoto = false
    @State private var showGuidelines = false
    @State private var showErase = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Me")
                    .font(.largeTitle.weight(.bold))
                HStack(spacing: 14) {
                    Button(action: { showPhoto = true }) {
                        HvpFaceView(asset: "HvpAvatarYou", mine: true, author: appStore.displayName, size: 72)
                    }
                    VStack(alignment: .leading) {
                        TextField("Display name", text: $name, onCommit: {
                            appStore.saveDisplayName(name)
                            stage.renameMine(to: appStore.displayName)
                        })
                        Text(HvpAppStore.handle(from: appStore.displayName))
                            .foregroundColor(HvpPalette.mute)
                        Text("\(stage.myWorks().count) clips · \(store.spotlights) Spotlights")
                            .font(.caption)
                            .foregroundColor(HvpPalette.mute)
                    }
                }

                NavigationLink(destination: HvpStoreView()) { row("Store") }
                NavigationLink(destination: HvpPrefsView()) { row("Booth prefs") }

                Text("Your clips").font(.headline)
                ForEach(stage.myWorks()) { clip in
                    NavigationLink(destination: HvpClipDetailView(clipId: clip.id)) {
                        Image(uiImage: HvpCoverArt.resolved(clip.coverAsset))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: { showGuidelines = true }) { row("Community Guidelines") }
                Button(action: { HvpAppCopy.openMail() }) { row("Contact") }
                NavigationLink(destination: HvpLegalPage(title: "Privacy Policy", url: URL(string: HvpAppCopy.privacyURL)!)) {
                    row("Privacy Policy")
                }
                NavigationLink(destination: HvpLegalPage(title: "Terms of Use", url: URL(string: HvpAppCopy.termsURL)!)) {
                    row("Terms of Use")
                }
                Button("Leave Session") { appStore.leaveSession() }
                    .buttonStyle(HvpSecondaryButtonStyle())
                Button("Delete Account") { showErase = true }
                    .foregroundColor(HvpPalette.rose)
                Text("Leave keeps clips on this iPhone. Delete Account removes your profile, videos, comments, and remaining Spotlights.")
                    .font(.footnote)
                    .foregroundColor(HvpPalette.mute)
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Me", displayMode: .inline)
        .onAppear { name = appStore.displayName }
        .sheet(isPresented: $showGuidelines) { HvpGuidelinesSheet() }
        .sheet(isPresented: $showPhoto) {
            HvpImagePicker(source: .photoLibrary) { image in
                showPhoto = false
                if let image { appStore.saveAvatar(image) }
            }
        }
        .alert(isPresented: $showErase) {
            Alert(
                title: Text("Delete Account?"),
                message: Text("This removes clips, media, comments, and \(store.spotlights) remaining Spotlights."),
                primaryButton: .destructive(Text("Delete")) {
                    stage.eraseEverything()
                    store.eraseBalance()
                    appStore.resetSessionFlags()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func row(_ title: String) -> some View {
        HStack {
            Text(title).foregroundColor(HvpPalette.ink)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(HvpPalette.mute)
        }
        .padding(14)
        .background(HvpPalette.plate)
        .cornerRadius(14)
    }
}

struct HvpStoreView: View {
    @EnvironmentObject private var store: HvpStoreManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Store")
                    .font(.largeTitle.weight(.bold))
                Text("\(store.spotlights) Spotlights on this iPhone")
                    .font(.title2.weight(.bold))
                Text("Saving a finished clip spends 1 Spotlight. Browsing, Photos, Record, liner notes, and preview do not spend.")
                    .foregroundColor(HvpPalette.mute)
                if !store.statusText.isEmpty {
                    Text(store.statusText).font(.footnote).foregroundColor(HvpPalette.mute)
                }
                ForEach(HvpStoreManager.catalog) { pack in
                    Button(action: { store.buy(pack) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pack.name).font(.headline)
                                Text(pack.fallbackPrice).foregroundColor(HvpPalette.mute)
                            }
                            Spacer()
                            Text(store.isBuying ? "…" : "Buy")
                                .font(.headline)
                        }
                        .padding(14)
                        .background(HvpPalette.plate)
                        .cornerRadius(16)
                    }
                    .disabled(store.isBuying)
                    .foregroundColor(HvpPalette.ink)
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Store", displayMode: .inline)
    }
}

struct HvpPrefsView: View {
    @EnvironmentObject private var appStore: HvpAppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Booth prefs").font(.largeTitle.weight(.bold))
                ForEach(HvpCategory.allCases) { item in
                    Button(item.rawValue) { appStore.saveCategory(item) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(appStore.category == item ? HvpPalette.violet : HvpPalette.plate)
                        .foregroundColor(appStore.category == item ? .white : HvpPalette.ink)
                        .cornerRadius(12)
                }
                ForEach(["720p", "1080p", "4K"], id: \.self) { q in
                    Button(q) { appStore.saveQuality(q) }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(appStore.quality == q ? HvpPalette.violet : HvpPalette.plate)
                        .foregroundColor(appStore.quality == q ? .white : HvpPalette.ink)
                        .cornerRadius(12)
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Booth prefs", displayMode: .inline)
    }
}

struct HvpGuidelinesPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Keep Board about music performance clips, liner notes, and craft. Do not post hate, off-topic promo, or spam. Report a clip from the more menu. Block a performer from their profile. Contact support@huvypum.app if you need help.")
                    .foregroundColor(HvpPalette.mute)
                ForEach(HvpHelpPages.pages.prefix(8), id: \.self) { page in
                    Text(page).font(.footnote).foregroundColor(HvpPalette.mute)
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Guidelines", displayMode: .inline)
    }
}

struct HvpGuidelinesSheet: View {
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        NavigationView {
            HvpGuidelinesPage()
                .navigationBarItems(trailing: Button("Close") { presentation.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
