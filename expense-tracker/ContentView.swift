import SwiftUI
import Charts

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false

    init() {
        Task { await self.checkAuth() }
    }

    func checkAuth() async {
        do {
            let session = try await supabase.auth.session
            DispatchQueue.main.async {
                self.isAuthenticated = session != nil
            }
        } catch {
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        }
    }

    func handleOpenURL(_ url: URL) async {
        do {
            try await supabase.auth.session(from: url)
            await checkAuth()
        } catch {
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        }
    }
}

struct GroupsTabWrapper: View {
    var body: some View {
        NavigationView {
            GroupsView()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            if authVM.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                        .tag(0)
                    TrackView()
                        .id(selectedTab == 1 ? UUID() : nil)
                        .tabItem {
                            Label("Track", systemImage: "plus.circle")
                        }
                        .tag(1)
                    GroupsTabWrapper()
                        .tabItem {
                            Label("Groups", systemImage: "person.3.fill")
                        }
                        .tag(2)
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(3)
                }
                .accentColor(.primary)
            } else {
                AuthView()
            }
        }
        .onOpenURL { url in
            Task { await authVM.handleOpenURL(url) }
        }
    }
}

#Preview {
    ContentView()
}
