import SwiftUI
import Supabase

struct LoginView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?
    @EnvironmentObject var authVM: AuthViewModel
    let onSwitchToSignup: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                Text("Sign in to your account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
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
                
                Button(action: signInButtonTapped) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.headline)
                            Text("Sign In")
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
                .disabled(isLoading || email.isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemBackground).opacity(0.8))
            .cornerRadius(24)
            .padding(.horizontal)
            
            if let result {
                switch result {
                case .success:
                    Text("Check your inbox for the login link.")
                        .foregroundColor(.primary)
                        .font(.subheadline)
                case .failure(let error):
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            
            HStack {
                Text("Don't have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Sign Up") {
                    onSwitchToSignup()
                }
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 32)
    }
    
    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await supabase.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "localhost:300")
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}
