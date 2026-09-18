import SwiftUI
import UIKit

enum HvpPalette {
    static let paper = Color(red: 0.957, green: 0.961, blue: 0.976)
    static let plate = Color.white
    static let ink = Color(red: 0.086, green: 0.094, blue: 0.149)
    static let mute = Color(red: 0.365, green: 0.392, blue: 0.478)
    static let line = Color(red: 0.365, green: 0.392, blue: 0.478).opacity(0.16)
    static let violet = Color(red: 0.420, green: 0.361, blue: 1.000)
    static let teal = Color(red: 0.169, green: 0.722, blue: 0.639)
    static let rose = Color(red: 0.851, green: 0.290, blue: 0.541)
}

enum HvpAppCopy {
    static let privacyURL = "https://huvypum-agreements.surge.sh/privacy-policy.html"
    static let termsURL = "https://huvypum-agreements.surge.sh/user-agreement.html"
    static let supportMail = "support@huvypum.app"
    static let saveCost = 1

    static func openMail() {
        if let url = URL(string: "mailto:\(supportMail)") {
            UIApplication.shared.open(url)
        }
    }
}

enum HvpKeys {
    static let hasEntered = "hvp.hasEntered"
    static let displayName = "hvp.displayName"
    static let didPromptLaunchPerms = "hvp.didPromptLaunchPerms"
    static let spotlights = "hvp.spotlights"
    static let category = "hvp.category"
    static let quality = "hvp.quality"
    static let filterOn = "hvp.filterOn"
}

struct HvpPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(HvpPalette.violet.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .cornerRadius(16)
    }
}

struct HvpSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(HvpPalette.plate)
            .foregroundColor(HvpPalette.ink)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HvpPalette.line, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct HvpTealButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(HvpPalette.teal.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(HvpPalette.ink)
            .cornerRadius(16)
    }
}

struct HvpFaceView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    let asset: String
    var mine: Bool = false
    var author: String = ""
    var size: CGFloat = 40

    var body: some View {
        Group {
            if showsCustom, let image = appStore.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(uiImage: HvpCoverArt.resolved(asset))
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var showsCustom: Bool {
        appStore.avatarImage != nil && (mine || author == appStore.displayName)
    }
}
