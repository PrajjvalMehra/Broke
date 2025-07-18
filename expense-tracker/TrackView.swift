import SwiftUI

struct TrackView: View {
    @State private var expenseName: String = ""
    @State private var expenseAmount: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var showAlert: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var todaysTotal: Double = 0.0
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
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.yellow.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Use a safe area inset for the header to avoid overlap with system status bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Track")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                .padding(.horizontal)
                .background(Color.white.opacity(0.01)) // invisible but helps with layout
                ScrollView {
                    VStack(spacing: 28) {
                        // Motivational message and quick stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Great job! You're keeping track of your spending.")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.green)
                                Text("Today's total: $\(todaysTotal, specifier: "%.2f")")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 8)
                        // Expense Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Expense Name")
                                .font(.headline)
                            TextField("Enter expense name", text: $expenseName)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .font(.body)
                                .focused($isInputFocused)
                        }
                        // Amount
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amount")
                                .font(.headline)
                            TextField("Enter amount", text: $expenseAmount)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .font(.body)
                                .focused($isInputFocused)
                        }
                        // Category selector with icons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(categories, id: \ .name) { category in
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
                                            .background(selectedCategory == category.name ? Color.green : Color.white.opacity(0.9))
                                            .foregroundColor(selectedCategory == category.name ? .white : .black)
                                            .cornerRadius(22)
                                            .shadow(color: selectedCategory == category.name ? Color.green.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 80) // Space for the pinned button
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
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
                                try await addUserExpense(expense: amount, category: selectedCategory, expenseName: expenseName)
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
                        .background(isSubmitting ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 2)
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
                    print("Today's total expense fetched on load:", total)
                    todaysTotal = total
                } catch {
                    print("Error fetching today's total expense:", error)
                }
            }
        }
    }
}
