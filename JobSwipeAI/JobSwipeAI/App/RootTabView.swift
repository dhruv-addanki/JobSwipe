import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "app.badge.fill")
            }

            NavigationStack {
                ApplicationsView()
            }
            .tabItem {
                Label("Applications", systemImage: "tray.full")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppEnvironment())
        .modelContainer(ModelContainerProvider.shared(inMemory: true))
}
