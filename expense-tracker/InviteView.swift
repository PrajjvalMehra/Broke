//
//  InviteView.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/21/25.
//

import SwiftUI

struct InviteView: View {
    let groupId: String
    @State private var inviteLink: String = ""
    @State private var showLink = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Button("Generate Invite") {
                Task {
                    do {
                        let token = try await generateInvite(groupId: groupId)
                        inviteLink = "https://yourapp.com/invite?token=\(token)"
                        showLink = true
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            if showLink {
                Text("Share this link:").bold()
                Text(inviteLink)
                    .textSelection(.enabled)
                    .foregroundColor(.blue)
                    .padding()
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Invite to Group")
    }
}
