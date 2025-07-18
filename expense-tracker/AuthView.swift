//
//  AuthView.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/14/25.
//

import SwiftUI
import Supabase

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State var email = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.yellow.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Sign In")
                        .font(.largeTitle.bold())
                        .foregroundColor(.green)
                    Text("Track your expenses across devices")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                        .font(.body)
                    Button(action: signInButtonTapped) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
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
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.15), radius: 8, x: 0, y: 2)
                        }
                    }
                    .disabled(isLoading || email.isEmpty)
                }
                .padding()
                .background(Color.white.opacity(0.25))
                .cornerRadius(24)
                .padding(.horizontal)
                if let result {
                    switch result {
                    case .success:
                        Text("Check your inbox.")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    case .failure(let error):
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 32)
        }
        .onOpenURL { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                    await authVM.checkAuth() // Update auth state after redirect
                } catch {
                    self.result = .failure(error)
                }
            }
        }
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

#Preview {
    AuthView()
}
