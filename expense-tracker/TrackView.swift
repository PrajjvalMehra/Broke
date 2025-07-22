import SwiftUI

struct TrackView: View {
    @State private var expenseName: String = ""
    @State private var expenseAmount: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var showAlert: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var todaysTotal: Double = 0.0
    @State private var displayName: String? = nil
    @State private var selectedGroupId: String? = nil
    @State private var groups: [Group] = []
    @FocusState private var isInputFocused: Bool

    let categories: [(name: String, icon: String)] = [
        ("Food", "fork.knife"),
        ("Transport", "car.fill"),
        ("Shopping", "bag.fill"),
        ("Bills", "doc.text.fill"),
        ("Entertainment", "gamecontroller.fill"),
        ("Other", "ellipsis")
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Use a safe area inset for the header to avoid overlap with system status bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Track")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let displayName {
                            Text(displayName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                .padding(.horizontal)
                ScrollView {
                    VStack(spacing: 28) {
                        // Motivational message and quick stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Great job! You're keeping track of your spending.")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.secondary)
                                Text("Today's total: $\(todaysTotal, specifier: "%.2f")")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 8)
                        // Group Picker (updated to horizontal button group)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Expense For")
                                .font(.headline)
                                .foregroundColor(.primary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    Button(action: {
                                        selectedGroupId = nil
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.fill")
                                                .font(.body)
                                            Text("Personal")
                                                .font(.body)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(selectedGroupId == nil ? Color.primary : Color(.secondarySystemBackground))
                                        .foregroundColor(selectedGroupId == nil ? Color(.systemBackground) : .primary)
                                        .cornerRadius(22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22)
                                                .stroke(selectedGroupId == nil ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                        )
                                        .shadow(color: selectedGroupId == nil ? Color.primary.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                    }
                                    ForEach(groups, id: \.id) { group in
                                        Button(action: {
                                            selectedGroupId = group.id
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "person.3.fill")
                                                    .font(.body)
                                                Text(group.name)
                                                    .font(.body)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(selectedGroupId == group.id ? Color.primary : Color(.secondarySystemBackground))
                                            .foregroundColor(selectedGroupId == group.id ? Color(.systemBackground) : .primary)
                                            .cornerRadius(22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .stroke(selectedGroupId == group.id ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                            )
                                            .shadow(color: selectedGroupId == group.id ? Color.primary.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                        // Expense Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Expense Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter expense name", text: $expenseName)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .font(.body)
                                .focused($isInputFocused)
                        }
                        // Amount
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amount")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter amount", text: $expenseAmount)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .font(.body)
                                .focused($isInputFocused)
                        }
                        // Category selector with icons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(categories, id: \.name) { category in
                                        Button(action: {
                                            selectedCategory = category.name
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: category.icon)
                                                    .font(.body)
                                                Text(category.name)
                                                    .font(.body)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(selectedCategory == category.name ? Color.primary : Color(.secondarySystemBackground))
                                            .foregroundColor(selectedCategory == category.name ? Color(.systemBackground) : .primary)
                                            .cornerRadius(22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .stroke(selectedCategory == category.name ? Color.clear : Color(.systemGray4), lineWidth: 1)
                                            )
                                            .shadow(color: selectedCategory == category.name ? Color.primary.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 80) // Space for the pinned button
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(28)
                    .padding()
                }
                .onTapGesture {
                    isInputFocused = false // Hide keyboard when tapping outside
                }
                // Pin the Add Expense button at the bottom
                Spacer(minLength: 0)
                VStack {
                    Button(action: {
                        isInputFocused = false
                        errorMessage = nil
                        guard let amount = Double(expenseAmount), !expenseName.isEmpty else {
                            errorMessage = "Please enter a valid name and amount."
                            return
                        }
                        isSubmitting = true
                        Task {
                            do {
                                try await addUserExpense(
                                    expense: Float(amount),
                                    category: selectedCategory,
                                    expenseName: expenseName,
                                    groupId: selectedGroupId // <-- Pass groupId here
                                )
                                showAlert = true
                                expenseName = ""
                                expenseAmount = ""
                                todaysTotal = try await fetchTodaysTotalExpense()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSubmitting = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.headline)
                            Text(isSubmitting ? "Adding..." : "Add Expense")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSubmitting ? Color(.systemGray3) : Color.primary)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: Color.primary.opacity(0.2), radius: 8, x: 0, y: 2)
                    }
                    .disabled(isSubmitting)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Expense Added!"), message: Text("Keep going! You're doing great."), dismissButton: .default(Text("OK")))
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            Task {
                do {
                    let total = try await fetchTodaysTotalExpense()
                    todaysTotal = total
                    displayName = try await fetchDisplayName()
                    groups = try await fetchGroupsForUser()
                } catch {
                    // Removed print statement
                }
            }
        }
    }
}
