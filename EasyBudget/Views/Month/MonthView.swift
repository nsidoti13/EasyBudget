import SwiftUI
import SwiftData

struct MonthView: View {
    let cycle: BudgetCycle

    private var vm: MonthViewModel { MonthViewModel(cycle: cycle) }

    var body: some View {
        List {
            Section {
                headerRow
                ForEach(vm.rows) { row in
                    dayRow(row)
                }
            } footer: {
                summary
            }
        }
        .navigationTitle("This month")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerRow: some View {
        HStack {
            Text("Day").frame(width: 70, alignment: .leading)
            Text("Budget").frame(maxWidth: .infinity, alignment: .trailing)
            Text("Spent").frame(maxWidth: .infinity, alignment: .trailing)
            Text("+/–").frame(width: 64, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .listRowBackground(Color.clear)
    }

    private func dayRow(_ row: MonthViewModel.Row) -> some View {
        HStack {
            Text(Formatters.dayShort.string(from: row.date))
                .frame(width: 70, alignment: .leading)
                .fontWeight(row.isToday ? .bold : .regular)

            Text(row.budget.asCurrencyWhole)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(row.isFuture ? .secondary : .primary)

            Group {
                if let spent = row.spent {
                    Text(spent.asCurrencyWhole)
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Group {
                if let delta = row.delta {
                    Text(delta.asSignedCurrencyWhole)
                        .foregroundStyle(delta >= 0 ? Theme.under : Theme.over)
                } else {
                    Text("").frame(width: 64)
                }
            }
            .frame(width: 64, alignment: .trailing)
        }
        .font(.subheadline.monospacedDigit())
        .listRowBackground(row.isToday ? Color.accentColor.opacity(0.10) : nil)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().padding(.bottom, 4)
            summaryLine("Monthly budget", vm.monthlyBudget.asCurrency)
            summaryLine("Spent so far", vm.totalSpent.asCurrency)
            summaryLine("Remaining", max(vm.remaining, 0).asCurrency, highlight: true)
        }
        .font(.subheadline)
        .padding(.top, 8)
    }

    private func summaryLine(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(highlight ? .bold : .regular)
        }
    }
}
