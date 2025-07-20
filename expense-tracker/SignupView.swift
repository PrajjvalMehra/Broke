import SwiftUI
import Supabase

struct SignupView: View {
    @State private var email = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    @EnvironmentObject var authVM: AuthViewModel
    let onSwitchToLogin: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                Text("Start tracking your expenses today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .font(.body)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .font(.body)
                
                Button(action: signUpButtonTapped) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.headline)
                            Text("Create Account")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.primary.opacity(0.2), radius: 8, x: 0, y: 2)
                    }
                }
                .disabled(isLoading || email.isEmpty || displayName.isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemBackground).opacity(0.8))
            .cornerRadius(24)
            .padding(.horizontal)
            
            if let result {
                switch result {
                case .success:
                    Text("Check your inbox to complete signup.")
                        .foregroundColor(.primary)
                        .font(.subheadline)
                case .failure(let error):
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            
            HStack {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Sign In") {
                    onSwitchToLogin()
                }
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 32)
    }
    
    func signUpButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await supabase.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "localhost:300"),
                    data: ["display_name": .string(displayName)]
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}
