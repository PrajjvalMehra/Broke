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
    @State private var showSignup = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if showSignup {
                SignupView(onSwitchToLogin: { showSignup = false })
            } else {
                LoginView(onSwitchToSignup: { showSignup = true })
            }
        }
        .onOpenURL { url in
            Task {
                do {
                    try await supabase.auth.session(from: url)
                    await authVM.checkAuth()
                } catch {
                    print("Error handling URL: \(error)")
                }
            }
        }
    }
}

#Preview {
    AuthView()
}
