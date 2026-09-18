import SwiftUI

struct HvpRootView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var store: HvpStoreManager

    var body: some View {
        Group {
            if appStore.hasEntered {
                HvpMainTabView()
            } else {
                HvpWelcomeView()
            }
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .onAppear {
            stage.load()
            store.loadBalance()
        }
    }
}
