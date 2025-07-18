import SwiftUI
import Charts
import Foundation
import UIKit

extension UIView {
    var recursiveSubviews: [UIView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}

struct ViewSizeKey: PreferenceKey {
    static var defaultValue: [CGSize] = []
    
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        value.append(contentsOf: nextValue())
    }
}

struct HistoryView: View {
    @State private var expenses: [UserExpense] = []
    @State private var dailyTotals: [(date: String, total: Float)] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var viewType: ViewType = .weekly
    
    enum ViewType {
        case weekly
        case monthly
        
        var title: String {
            switch self {
            case .weekly: return "Last 7 Days"
            case .monthly: return "Last 12 Months"
            }
        }
    }
    
    private func formattedDate(_ dateString: String, showYear: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            if showYear {
                displayFormatter.dateFormat = "MMM d, yy"
            } else {
                displayFormatter.dateFormat = "MMM d"
            }
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func formattedPeriodLabel(_ dateString: String, viewType: ViewType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let labelFormatter = DateFormatter()
        switch viewType {
        case .weekly:
            labelFormatter.dateFormat = "EEE"
        case .monthly:
            labelFormatter.dateFormat = "MMM"
        }
        return labelFormatter.string(from: date)
    }
    
    private func fillEmptyPeriods(_ totals: [(date: String, total: Float)], viewType: ViewType) -> [(date: String, total: Float)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var filled: [(date: String, total: Float)] = []

        switch viewType {
        case .weekly:
            // Fill last 7 days (including today and previous 6 days)
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
            // Fill last 12 months
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
    
    private func periodString(start: String?, end: String?) -> String {
        guard let start = start, let end = end else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else { return "" }
        
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

    // Filter expenses for the current view (week or month)
    private var filteredExpenses: [UserExpense] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        switch viewType {
        case .weekly:
            // Show expenses from the last 7 days (including today)
            let startOfToday = calendar.startOfDay(for: now)
            let weekAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            return expenses.filter { exp in
                if let date = ISO8601DateFormatter().date(from: exp.created_at) ?? formatter.date(from: exp.created_at) {
                    let localDate = calendar.startOfDay(for: date)
                    return localDate >= weekAgo && localDate <= startOfToday
                }
                return false
            }
        case .monthly:
            // Show expenses from the last 12 months (including this month)
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let yearAgo = calendar.date(byAdding: .month, value: -11, to: startOfMonth)!
            return expenses.filter { exp in
                if let date = ISO8601DateFormatter().date(from: exp.created_at) ?? formatter.date(from: exp.created_at) {
                    let localDate = calendar.startOfDay(for: date)
                    return localDate >= yearAgo && localDate <= now
                }
                return false
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 24)
                .padding(.horizontal)
                VStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                            .tint(.blue)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                        Spacer()
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if expenses.isEmpty {
                        Text("No expenses yet.")
                            .foregroundColor(.gray)
                    } else {
                        let filledTotals = fillEmptyPeriods(dailyTotals, viewType: viewType)
                        let total: Float = {
                            switch viewType {
                            case .weekly:
                                return filledTotals.reduce(0) { $0 + $1.total }
                            case .monthly:
                                return filledTotals.last?.total ?? 0
                            }
                        }()
                        // align to the left of the screen
                        HStack(alignment: .top) {
                            // Dropdown menu on the left, aligned with header
                            Menu {
                                Button(action: { viewType = .weekly }) {
                                    HStack {
                                        Text("Weekly")
                                        if viewType == .weekly {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button(action: { viewType = .monthly }) {
                                    HStack {
                                        Text("Monthly")
                                        if viewType == .monthly {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(viewType == .weekly ? "Weekly" : "Monthly")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(8)
                            }
                            // Remove left padding
                            .padding(.leading, 0)
                            Spacer()
                            // Total and period on the right
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Total")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gray)
                                Text("$\(total, specifier: "%.2f")")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.blue)
                                Text(periodString(start: filledTotals.first?.date, end: filledTotals.last?.date))
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                    .padding(.trailing, 0) // Remove right padding
                            }
                        }
                        .padding(.bottom, 8)
                        Chart {
                            ForEach(filledTotals, id: \.date) { period in
                                BarMark(
                                    x: .value("Period", formattedPeriodLabel(period.date, viewType: viewType)),
                                    y: .value("Total", period.total)
                                )
                                .foregroundStyle(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .font(.caption)
                            }
                        }
                        .frame(height: 200)
                        .frame(width: nil)
                        .padding(.bottom)
                        List(filteredExpenses, id: \.created_at) { expense in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.expense_name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    HStack(spacing: 6) {
                                        Text(expense.category)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        Text("•")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                        Text(formattedDate(String(expense.created_at.prefix(10)), showYear: true))
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Text("$\(expense.expense, specifier: "%.2f")")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(10)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                        .scrollIndicators(.hidden)
                        .environment(\.defaultMinListRowHeight, 0)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                do {
                    isLoading = true
                    expenses = try await fetchAllUserExpenses()
                    dailyTotals = groupExpensesByDay(expenses)
                    isLoading = false
                } catch {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

func groupExpensesByDay(_ expenses: [UserExpense]) -> [(date: String, total: Float)] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current // Use device's timezone
    let utcFormatter = ISO8601DateFormatter()
    utcFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    utcFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    let grouped = Dictionary(grouping: expenses) { expense in
        // Try to parse the UTC date string and convert to local date string
        if let utcDate = utcFormatter.date(from: expense.created_at) {
            return formatter.string(from: utcDate)
        } else {
            // fallback: just use the first 10 chars
            return String(expense.created_at.prefix(10))
        }
    }
    return grouped.map { (date, items) in
        (date: date, total: items.reduce(0) { $0 + $1.expense })
    }.sorted { $0.date < $1.date }
}
