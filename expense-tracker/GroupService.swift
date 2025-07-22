//
//  GroupService.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/21/25.
//

import Foundation

// Create a group
func createGroup(name: String) async throws -> Group {
    let session = try await supabase.auth.session
    let userId = String(describing: session.user.id)
    // 1. Create the group
    let response: [Group] = try await supabase
        .from("groups")
        .insert(["name": name, "created_by": userId])
        .select()
        .execute()
        .value
    guard let group = response.first else {
        throw NSError(domain: "Failed to create group", code: 500)
    }
    // 2. Add creator as a member
    _ = try await supabase
        .from("group_members")
        .insert(["group_id": group.id, "user_id": userId])
        .execute()
    return group
}

// Generate invite token
func generateInvite(groupId: String) async throws -> String {
    let session = try await supabase.auth.session
    let userId = String(describing: session.user.id)
    let token = UUID().uuidString // Generate unique token
    let response = try await supabase
        .from("GroupInvites")
        .insert(["group_id": groupId, "inviter_uid": userId, "invite_token": token, "is_used": "false"])
        .select()
        .execute()
    return token
}

// Accept invite link (token)
func acceptInvite(token: String) async throws -> GroupMember {
    let session = try await supabase.auth.session
    let userId = String(describing: session.user.id)
    let invite: [GroupInvite] = try await supabase
        .from("group_invites")
        .select("group_id,is_used")
        .eq("token", value: token)
        .execute()
        .value
    guard let inviteObj = invite.first, inviteObj.is_used == false else {
        throw NSError(domain: "Invite invalid or used", code: 400)
    }
    // Add user to group_members
    let memberResponse: [GroupMember] = try await supabase
        .from("group_members")
        .insert(["group_id": inviteObj.group_id, "user_id": userId])
        .select()
        .execute()
        .value
    // Mark invite as used
    _ = try await supabase
        .from("group_invites")
        .update(["is_used": "true"]) // Use string value instead of Bool
        .eq("token", value: token)
        .execute()
    return memberResponse.first!
}

// Fetch groups for the current user (as a member)
func fetchGroupsForUser() async throws -> [Group] {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    // Fetch all group_members for this user
    let groupMembers: [GroupMember] = try await supabase
        .from("group_members")
        .select("group_id,user_id,joined_at") // Include joined_at
        .eq("user_id", value: uid)
        .execute()
        .value
    let groupIds = groupMembers.map { $0.group_id }
    if groupIds.isEmpty {
        return []
    }
    // Supabase expects a dictionary for the .in operator
    let response: [Group] = try await supabase
        .from("groups")
        .select("*")
        .in("id", values: groupIds)
        .execute()
        .value
    return response
}

// Fetch group expenses (by group_id)
func fetchGroupExpenses(groupId: String) async throws -> [UserExpense] {
    let response: [UserExpense] = try await supabase
        .from("User Expenses")
        .select("expense,uid,category,expense_name,created_at,group_id")
        .eq("group_id", value: groupId)
        .order("created_at", ascending: false)
        .execute()
        .value
    return response
}

// Fetch group name by group ID
func fetchGroupName(groupId: String) async throws -> String? {
    print("Fetching group name for ID: \(groupId)")
    let response: [Group] = try await supabase
        .from("groups")
        .select("id, name, created_by, created_at")
        .eq("id", value: groupId)
        .execute()
        .value
    print("Response: \(response)")
    return response.first?.name
}
