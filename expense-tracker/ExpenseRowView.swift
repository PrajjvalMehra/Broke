import SwiftUI

struct ExpenseRowView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
            .padding()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }
}
