import Foundation

func addUserExpense(expense: Double, category: String, expenseName: String) async throws {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    try await addExpense(expense: expense, uid: uid, category: category, expenseName: expenseName)
}

struct UserExpense: Decodable {
    let expense: Float
    let uid: String
    let category: String
    let expense_name: String
    let created_at: String
}

struct TodayExpense: Decodable {
    let expense: Double
}

func fetchTodaysTotalExpense() async throws -> Double {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
    print(uid)
    let response: [TodayExpense] = try await supabase
        .from("User Expenses")
        .select("expense")
        .eq("uid", value: uid)
        .gte("created_at", value: today)
        .execute()
        .value
    
    let totalExpense = response.reduce(0) { $0 + Double($1.expense) }
    return totalExpense
}

func fetchAllUserExpenses() async throws -> [UserExpense] {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    let response: [UserExpense] = try await supabase
        .from("User Expenses")
        .select("expense,uid,category,expense_name,created_at")
        .eq("uid", value: uid)
        .order("created_at", ascending: false)
        .execute()
        .value
    return response
}
