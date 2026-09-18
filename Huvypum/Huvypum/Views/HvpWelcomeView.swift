import SwiftUI

struct HvpWelcomeView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @State private var agreed = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(uiImage: HvpCoverArt.resolved("HvpHeroWelcome"))
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(28)

                    Text("Huvypum")
                        .font(.largeTitle.weight(.bold))
                    Text("Watch short music performance clips, keep the takes you love, and save your own liner-note clip to the board.")
                        .foregroundColor(HvpPalette.mute)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Camera captures a new performance fragment when you tap Record.")
                        Text("Photos chooses an existing take when you tap Photos.")
                        Text("Microphone records a spoken liner note when you tap Voice note, and room sound when you tap Record.")
                    }
                    .font(.subheadline)
                    .foregroundColor(HvpPalette.mute)

                    HvpWelcomeAgreeRow(agreed: $agreed)

                    Button("Create Performance Clip") {
                        guard agreed else { return }
                        appStore.enterFromWelcome()
                    }
                    .buttonStyle(HvpPrimaryButtonStyle())
                    .disabled(!agreed)
                    .opacity(agreed ? 1 : 0.45)

                    Button("Browse the board") {
                        guard agreed else { return }
                        appStore.enterQuietly()
                    }
                    .buttonStyle(HvpSecondaryButtonStyle())
                    .disabled(!agreed)
                    .opacity(agreed ? 1 : 0.45)

                    if !agreed {
                        Text("Agree to the Privacy Policy and Terms of Use to continue.")
                            .font(.footnote)
                            .foregroundColor(HvpPalette.mute)
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(HvpPalette.paper.ignoresSafeArea())
            .navigationBarTitle("Welcome", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HvpWelcomeAgreeRow: View {
    @Binding var agreed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: { agreed.toggle() }) {
                Image(systemName: agreed ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(agreed ? HvpPalette.violet : HvpPalette.mute)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 8) {
                Text("I have read and agree to the Privacy Policy and Terms of Use.")
                    .font(.subheadline)
                    .foregroundColor(HvpPalette.ink)
                NavigationLink(destination: HvpLegalPage(title: "Privacy Policy", url: URL(string: HvpAppCopy.privacyURL)!)) {
                    Text("Privacy Policy")
                }
                NavigationLink(destination: HvpLegalPage(title: "Terms of Use", url: URL(string: HvpAppCopy.termsURL)!)) {
                    Text("Terms of Use")
                }
            }
        }
        .padding(14)
        .background(HvpPalette.plate)
        .cornerRadius(18)
    }
}

struct HvpLegalPage: View {
    @Environment(\.presentationMode) private var presentation
    let title: String
    let url: URL

    private var bundledFile: String {
        title == "Privacy Policy" ? "privacy-policy" : "user-agreement"
    }

    var body: some View {
        HvpInAppWebView(url: url, bundledFile: bundledFile)
            .background(HvpPalette.paper.ignoresSafeArea())
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(trailing: Button("Done") { presentation.wrappedValue.dismiss() })
    }
}
