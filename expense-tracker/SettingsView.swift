import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var displayName: String = ""
    @State private var isDisplayNameLoading = false
    @State private var displayNameMessage: String?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
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
                        .background(Color.primary)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.primary.opacity(0.15), radius: 8, x: 0, y: 2)
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
                // Display Name Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Display Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack {
                        TextField("Enter your display name", text: $displayName)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .disabled(isDisplayNameLoading)
                        Button(action: saveDisplayName) {
                            if isDisplayNameLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save")
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(displayName.isEmpty ? Color(.systemGray3) : Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isDisplayNameLoading || displayName.isEmpty)
                    }
                    if let displayNameMessage {
                        Text(displayNameMessage)
                            .foregroundColor(.primary)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                Spacer()
            }
        }
        .onAppear {
            loadDisplayName()
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
    
    func loadDisplayName() {
        isDisplayNameLoading = true
        displayNameMessage = nil
        Task {
            do {
                if let name = try await fetchDisplayName() {
                    displayName = name
                } else {
                    displayName = ""
                }
            } catch {
                displayNameMessage = "Failed to load display name."
            }
            isDisplayNameLoading = false
        }
    }
    
    func saveDisplayName() {
        isDisplayNameLoading = true
        displayNameMessage = nil
        Task {
            do {
                try await updateDisplayName(newName: displayName)
                displayNameMessage = "Display name updated!"
            } catch {
                displayNameMessage = "Failed to update display name."
            }
            isDisplayNameLoading = false
        }
    }
}
