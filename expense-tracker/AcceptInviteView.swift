//
//  AcceptInviteView.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/21/25.
//

import SwiftUI

struct AcceptInviteView: View {
    let token: String
    @State private var message: String = ""

    var body: some View {
        VStack {
            Button("Join Group") {
                Task {
                    do {
                        let member = try await acceptInvite(token: token)
                        message = "You have joined the group!"
                    } catch {
                        message = "Failed to join: \(error.localizedDescription)"
                    }
                }
            }
            if !message.isEmpty {
                Text(message)
                    .padding()
            }
        }
        .padding()
    }
}
