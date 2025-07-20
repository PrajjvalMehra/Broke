import SwiftUI

struct ExpenseListView: View {
    let filteredExpenses: [UserExpense]
    let formattedDate: (String, Bool) -> String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(
                    Dictionary(grouping: filteredExpenses, by: { String($0.created_at.prefix(10)) })
                        .sorted(by: { $0.key > $1.key }),
                    id: \ .key
                ) { date, expensesForDate in
                    Section {
                        VStack(spacing: 0) {
                            ForEach(expensesForDate.indices, id: \ .self) { index in
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
                        Text(formattedDate(date, true))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
