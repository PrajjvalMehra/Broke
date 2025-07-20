import SwiftUI

struct ExpenseRowView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sample Expense")
                    .font(.headline)
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("$0.00")
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
    }
}
