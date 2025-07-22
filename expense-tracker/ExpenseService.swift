import Foundation

func addUserExpense(expense: Float, category: String, expenseName: String, groupId: String? = nil) async throws {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    try await addExpense(expense: expense, uid: uid, category: category, expenseName: expenseName, groupId: groupId)
}

struct UserExpense: Decodable, Identifiable {
    let id: Int
    let expense: Float
    let uid: String
    let category: String
    let expense_name: String
    let created_at: String
    let group_id: String?
}

struct ExpenseBasic: Decodable {
    let id: Int
    let expense: Float
    let uid: String
    let expense_name: String
}

func updateUserExpense(id: Int, expense: Double, category: String, expenseName: String) async throws {
    let session = try await supabase.auth.session
    let uid = session.user.id.uuidString
    
    // Create a struct that conforms to Encodable with only the fields to update
    struct ExpenseUpdate: Encodable {
        let expense: Float
        let category: String
        let expense_name: String
        let id: Int
    }
    
    let updateData = ExpenseUpdate(
        expense: Float(expense),
        category: category,
        expense_name: expenseName,
        id: id
    )
    
    do {
        let response = try await supabase
            .from("User Expenses")
            .update(updateData)
            .eq("id", value: id)
            .eq("uid", value: uid)
            .execute()
    } catch {
        throw error
    }
}

func deleteUserExpense(id: Int) async throws {
    do {
        let response = try await supabase
            .from("User Expenses")
            .delete()
            .eq("id", value: id)
            .execute()
    } catch {
        throw error
    }
}

func fetchTodaysTotalExpense() async throws -> Double {
    let session = try await supabase.auth.session
    let uid = String(describing: session.user.id)
    let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
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
    do {
        let session = try await supabase.auth.session
        let uid = String(describing: session.user.id)
        let response: [UserExpense] = try await supabase
            .from("User Expenses")
            .select("id,expense,uid,category,expense_name,created_at,group_id")
            .eq("uid", value: uid)
            .order("created_at", ascending: false)
            .execute()
            .value
        print("Fetched \(response.count) expenses for user \(uid)")
        for expense in response {
            print("Expense ID: \(expense.id), Amount: \(expense.expense), Name: \(expense.expense_name), Category: \(expense.category), Created At: \(expense.created_at), Group ID: \(String(describing: expense.group_id))")
        }
        
        return response
    } catch {
        throw error
    }
}
