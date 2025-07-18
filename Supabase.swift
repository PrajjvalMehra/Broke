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
    let expense: Double
    let uid: String
    let category: String
    let expense_name: String
    let created_at: String?
}

func addExpense(expense: Double, uid: String, category: String, expenseName: String, createdAt: String? = nil) async throws {
    let newExpense = ExpenseInsert(expense: expense, uid: uid, category: category, expense_name: expenseName, created_at: createdAt)
    _ = try await supabase.database.from("User Expenses").insert(newExpense).execute()
}
