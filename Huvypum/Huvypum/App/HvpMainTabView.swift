import SwiftUI

struct HvpMainTabView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationView {
                HvpFeedView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem { Label("Board", systemImage: "rectangle.stack.fill") }
            .tag(0)

            NavigationView {
                HvpBoothView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem { Label("Booth", systemImage: "record.circle") }
            .tag(1)

            NavigationView {
                HvpNightsView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem { Label("Nights", systemImage: "building.columns") }
            .tag(2)

            NavigationView {
                HvpMeView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem { Label("Me", systemImage: "person.crop.circle") }
            .tag(3)
        }
        .accentColor(HvpPalette.violet)
        .onAppear {
            appStore.promptLaunchPermissionsIfNeeded()
            if appStore.openBoothOnEnter {
                tab = 1
                appStore.openBoothOnEnter = false
            }
        }
    }
}
