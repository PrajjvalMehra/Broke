//
//  Supabase.swift
//  expense-tracker
//
//  Created by Prajjval mehra on 7/14/25.
//

import Foundation
import Supabase
let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://trbndyjsdkefffdlamgd.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyYm5keWpzZGtlZmZmZGxhbWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1Mjg4NzksImV4cCI6MjA2ODEwNDg3OX0.-gC20XRkEMCwPQbD6yoeYSBwQEe4_S_wkD1coB29Izs"
)

struct ExpenseInsert: Codable {
    let expense: Float
    let uid: String
    let category: String
    let expense_name: String
    let created_at: String?
    let group_id: String?
}

func addExpense(
    expense: Float,
    uid: String,
    category: String,
    expenseName: String,
    groupId: String? = nil,
    createdAt: String? = nil
) async throws {
    let newExpense = ExpenseInsert(
        expense: expense,
        uid: uid,
        category: category,
        expense_name: expenseName,
        created_at: createdAt,
        group_id: groupId
    )
    _ = try await supabase
        .database
        .from("User Expenses")
        .insert(newExpense)
        .execute()
}
func fetchDisplayName() async throws -> String? {
    let session = try await supabase.auth.session
    print("User metadata: \(session.user.userMetadata)")
    
    // Try different possible keys for display name
    if let displayNameJSON = session.user.userMetadata["display_name"],
       let displayName = (displayNameJSON as? CustomStringConvertible)?.description {
        return displayName
    }
    
    // Fallback: try other possible metadata keys
    if let displayNameJSON = session.user.userMetadata["full_name"],
       let displayName = (displayNameJSON as? CustomStringConvertible)?.description {
        return displayName
    }
    
    if let displayNameJSON = session.user.userMetadata["name"],
       let displayName = (displayNameJSON as? CustomStringConvertible)?.description {
        return displayName
    }
    
    return nil
}

func updateDisplayName(newName: String) async throws {
    let attributes = UserAttributes(data: ["display_name": .string(newName)])
    _ = try await supabase.auth.update(user: attributes)
}

func signUpWithDisplayName(email: String, displayName: String) async throws {
    try await supabase.auth.signInWithOTP(
        email: email,
        redirectTo: URL(string: "localhost:300"),
        data: ["display_name": .string(displayName)]
    )
}
