import Foundation

func groupExpensesByDay(_ expenses: [UserExpense]) -> [(date: String, total: Float)] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    let utcFormatter = ISO8601DateFormatter()
    utcFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    let grouped = Dictionary(grouping: expenses) { expense in
        if let utcDate = utcFormatter.date(from: expense.created_at) {
            return formatter.string(from: utcDate)
        } else {
            return String(expense.created_at.prefix(10))
        }
    }
    return grouped.map { (date, items) in
        (date: date, total: items.reduce(0) { $0 + $1.expense })
    }.sorted { $0.date < $1.date }
}
