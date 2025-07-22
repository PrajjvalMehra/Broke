import Foundation

func localDayStart(from created_at: String) -> Date? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    if let utcDate = isoFormatter.date(from: created_at) {
        let localDate = utcDate.addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT(for: utcDate)))
        return Calendar.current.startOfDay(for: localDate)
    }
    return nil
}

func formattedDate(_ dateString: String, showYear: Bool = true) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = showYear ? "MMM d, yy" : "MMM d"
        return displayFormatter.string(from: date)
    }
    return dateString
}

func formattedPeriodLabel(_ dateString: String, viewType: HistoryView.ViewType) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: dateString) else { return dateString }
    let labelFormatter = DateFormatter()
    labelFormatter.dateFormat = viewType == .weekly ? "EEE" : "MMM"
    return labelFormatter.string(from: date)
}

func fillEmptyPeriods(_ totals: [(date: String, total: Float)], viewType: HistoryView.ViewType) -> [(date: String, total: Float)] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var filled: [(date: String, total: Float)] = []
    switch viewType {
    case .weekly:
        for i in (0...6).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = formatter.string(from: date)
                if let found = totals.first(where: { $0.date == dateString }) {
                    filled.append(found)
                } else {
                    filled.append((date: dateString, total: 0))
                }
            }
        }
    case .monthly:
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        for i in (0..<12).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: startOfMonth) {
                let dateString = formatter.string(from: date)
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                let monthlyTotal = totals.filter { total in
                    if let totalDate = formatter.date(from: total.date) {
                        return totalDate >= monthStart && totalDate < nextMonth
                    }
                    return false
                }.reduce(0) { $0 + $1.total }
                filled.append((date: dateString, total: monthlyTotal))
            }
        }
    }
    return filled
}

func periodString(start: String?, end: String?, viewType: HistoryView.ViewType) -> String {
    guard let start = start, let end = end else { return "" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    guard let startDate = formatter.date(from: start), let endDate = formatter.date(from: end) else { return "" }
    switch viewType {
    case .weekly:
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMMM d"
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMMM d, yy"
        return "\(startFormatter.string(from: startDate)) - \(endFormatter.string(from: endDate))"
    case .monthly:
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMMM yyyy"
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMMM yyyy"
        return "\(startFormatter.string(from: startDate)) - \(endFormatter.string(from: endDate))"
    }
}

func localDateString(from created_at: String) -> String {
    if let localDayStart = localDayStart(from: created_at) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: localDayStart)
    } else {
        return String(created_at.prefix(10))
    }
}

//func groupExpensesByDay(_ expenses: [UserExpense]) -> [(date: String, total: Float)] {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "yyyy-MM-dd"
//    dateFormatter.timeZone = TimeZone.current
//    let grouped = Dictionary(grouping: expenses) { expense in
//        if let localDayStart = localDayStart(from: expense.created_at) {
//            return dateFormatter.string(from: localDayStart)
//        } else {
//            return String(expense.created_at.prefix(10))
//        }
//    }
//    return grouped.map { (date, items) in
//        (date: date, total: items.reduce(0) { $0 + $1.expense })
//    }.sorted { $0.date < $1.date }
//}
