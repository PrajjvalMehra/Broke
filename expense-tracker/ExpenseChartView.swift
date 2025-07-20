import SwiftUI
import Charts

struct ExpenseChartView: View {
    let filledTotals: [(date: String, total: Float)]
    let viewType: HistoryView.ViewType
    let animateChart: Bool
    let formattedPeriodLabel: (String, HistoryView.ViewType) -> String

    var body: some View {
        let animatedTotals = animateChart ? filledTotals : filledTotals.map { ($0.date, 0 as Float) }
        Chart {
            ForEach(Array(animatedTotals.enumerated()), id: \ .element.0) { idx, period in
                BarMark(
                    x: .value("Period", formattedPeriodLabel(period.0, viewType)),
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
        .padding(.horizontal)
        .padding(.bottom)
    }
}
