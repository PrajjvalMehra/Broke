//
//  GroupModels.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/21/25.
//

import Foundation

struct Group: Identifiable, Codable {
    let id: String
    let name: String
    let created_by: String
    let created_at: String
}

struct GroupInvite: Identifiable, Codable {
    var id: String { token } // <-- Add this computed property
    let token: String
    let group_id: String
    let invited_by: String
    let is_used: Bool
    let created_at: String
}

struct GroupMember: Codable {
    let group_id: String
    let user_id: String
    let joined_at: String
}
