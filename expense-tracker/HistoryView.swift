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
    @State private var animateChart = false
    @State private var expenseToEdit: UserExpense?
    @State private var showingEditExpense = false
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: UserExpense?
    @State private var isDeleting: Bool = false
    
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

    private func refreshData() {
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
    
    private func deleteExpense(_ expense: UserExpense) {
        isDeleting = true
        Task {
            do {
                try await (deleteUserExpense)(id: expense.id)
                await MainActor.run {
                    refreshData()
                    isDeleting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete expense: \(error.localizedDescription)"
                    isDeleting = false
                }
            }
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
            Color(.systemBackground)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                        Spacer()
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if expenses.isEmpty {
                        Text("No expenses yet.")
                            .foregroundColor(.secondary)
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
                        HStack(alignment: .top) {
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
                                        .foregroundColor(.primary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .padding(.leading, 0)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Total")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("$\(total, specifier: "%.2f")")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.primary)
                                Text(periodString(start: filledTotals.first?.date, end: filledTotals.last?.date))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 0)
                            }
                        }
                        .padding(.horizontal) // <-- Add horizontal padding to HStack (dropdown + period)
                        .padding(.bottom, 4)
                        let animatedTotals = animateChart ? filledTotals : filledTotals.map { ($0.date, 0 as Float) }
                        Chart {
                            ForEach(Array(animatedTotals.enumerated()), id: \ .element.0) { idx, period in
                                BarMark(
                                    x: .value("Period", formattedPeriodLabel(period.0, viewType: viewType)),
                                    y: .value("Total", period.1)
                                )
                                .foregroundStyle(LinearGradient(
                                    gradient: Gradient(colors: [Color.primary.opacity(0.8), Color.secondary.opacity(0.6)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 200)
                        .frame(width: nil)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .onAppear {
                            animateChart = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    animateChart = true
                                }
                            }
                        }
                        .onChange(of: isLoading) { _, _ in
                            if !isLoading {
                                animateChart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        animateChart = true
                                    }
                                }
                            }
                        }
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                ForEach(
                                    Dictionary(grouping: filteredExpenses, by: { String($0.created_at.prefix(10)) })
                                        .sorted(by: { $0.key > $1.key }),
                                    id: \.key
                                ) { date, expensesForDate in
                                    Section {
                                        VStack(spacing: 0) {
                                            ForEach(expensesForDate.indices, id: \.self) { index in
                                                let expense = expensesForDate[index]
                                                VStack(spacing: 0) {
                                                    HStack(spacing: 12) {
                                                        Text("$\(expense.expense, specifier: "%.2f")")
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(.primary)
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(expense.expense_name)
                                                                .font(.system(size: 15, weight: .semibold))
                                                                .foregroundColor(.primary)
                                                                .lineLimit(1)
                                                            Text(expense.category)
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.secondary)
                                                        }
                                                        Spacer()
                                                        
                                                        Menu {
                                                            Button(action: {
                                                                expenseToEdit = expense
                                                                showingEditExpense = true
                                                            }) {
                                                                HStack {
                                                                    Text("Edit")
                                                                    Image(systemName: "pencil")
                                                                }
                                                            }
                                                            
                                                            Button(role: .destructive, action: {
                                                                expenseToDelete = expense
                                                                showingDeleteAlert = true
                                                            }) {
                                                                HStack {
                                                                    Text("Delete")
                                                                    Image(systemName: "trash")
                                                                }
                                                            }
                                                        } label: {
                                                            Image(systemName: "ellipsis")
                                                                .font(.system(size: 16, weight: .medium))
                                                                .foregroundColor(.secondary)
                                                                .frame(width: 32, height: 32)
                                                                .background(Color(.systemGray5))
                                                                .clipShape(Circle())
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color(.systemGray6))
                                                    
                                                    if index < expensesForDate.count - 1 {
                                                        Divider()
                                                            .background(Color(.systemGray4))
                                                            .padding(.horizontal, 16)
                                                    }
                                                }
                                            }
                                        }
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    } header: {
                                        Text(formattedDate(date, showYear: true))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemBackground)) // Solid background
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
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
        .sheet(item: $expenseToEdit) { expense in
            EditExpenseView(expense: expense) {
                refreshData()
            }
        }
        .alert("Delete Expense", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let expenseToDelete = expenseToDelete {
                    deleteExpense(expenseToDelete)
                }
            }
        } message: {
            if let expenseToDelete = expenseToDelete {
                Text("Are you sure you want to delete '\(expenseToDelete.expense_name)' for $\(expenseToDelete.expense, specifier: "%.2f")?")
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
