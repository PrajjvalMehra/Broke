import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.headline)
                            Text(isLoading ? "Logging out..." : "Logout")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.red.opacity(0.15), radius: 8, x: 0, y: 2)
                    }
                    .disabled(isLoading)
                }
                .padding(.vertical, 24)
                .padding(.horizontal)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
    func logout() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await supabase.auth.signOut()
                await authVM.checkAuth() // Ensure checkAuth is called after signOut
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
}
