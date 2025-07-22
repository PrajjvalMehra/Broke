//
//  Untitled.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/21/25.
//

import SwiftUI

struct GroupsView: View {
    @State private var groups: [Group] = []
    @State private var newGroupName: String = ""
    @State private var showAlert = false

    var body: some View {
        VStack {
            TextField("New Group Name", text: $newGroupName)
                .padding()
            Button("Create Group") {
                Task {
                    do {
                        let group = try await createGroup(name: newGroupName)
                        groups.append(group)
                        newGroupName = ""
                        showAlert = true
                    } catch {
                        // handle error
                    }
                }
            }
            List(groups) { group in
                HStack {
                    Text(group.name)
                    Spacer()
                    NavigationLink("Invite", destination: InviteView(groupId: group.id))
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Group Created"), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            Task {
                // Fetch groups for current user (implement fetchGroups)
            }
        }
    }
}
