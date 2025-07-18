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


struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: Int = 0
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                        .tag(0)
                    TrackView()
                        .tabItem {
                            Label("Track", systemImage: "plus.circle")
                        }
                        .tag(1)
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(2)
                }
                .accentColor(tabAccentColor)
            } else {
                AuthView()
            }
        }
        .onOpenURL { url in
            Task { await authVM.handleOpenURL(url) }
        }
    }
    
    private var tabAccentColor: Color {
        switch selectedTab {
        case 0: return Color.purple // History theme
        case 1: return Color.green  // Track theme
        case 2: return Color.blue   // Settings theme
        default: return Color.red
        }
    }
}

#Preview {
    ContentView()
}
