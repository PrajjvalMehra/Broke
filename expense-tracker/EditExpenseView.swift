import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var expenseAmount: String
    @State private var expenseName: String
    @State private var selectedCategory: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let expense: UserExpense
    let onSave: () -> Void
    
    let categories = ["Food", "Transportation", "Entertainment", "Shopping", "Bills", "Healthcare", "Education", "Other"]
    
    init(expense: UserExpense, onSave: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        self._expenseAmount = State(initialValue: String(format: "%.2f", expense.expense))
        self._expenseName = State(initialValue: expense.expense_name)
        self._selectedCategory = State(initialValue: expense.category)
    }
    
    private var isValidInput: Bool {
        guard let amount = Double(expenseAmount), amount > 0 else { return false }
        return !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("$")
                                .font(.title2)
                                .foregroundColor(.primary)
                            TextField("0.00", text: $expenseAmount)
                                .keyboardType(.decimalPad)
                                .font(.title2)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expense Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter expense name", text: $expenseName)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Menu {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    HStack {
                                        Text(category)
                                        if selectedCategory == category {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCategory)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: saveExpense) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Update Expense")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidInput ? (colorScheme == .dark ? Color.white : Color.black) : Color(.systemGray3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .disabled(!isValidInput || isLoading)
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveExpense() {
        guard let amount = Double(expenseAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an expense name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await updateUserExpense(
                    id: expense.id,
                    expense: amount,
                    category: selectedCategory,
                    expenseName: expenseName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update expense: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
