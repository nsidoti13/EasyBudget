import Foundation

/// Builds the per-day rows and summary for the current cycle.
struct MonthViewModel {
    struct Row: Identifiable {
        let id: Date
        let date: Date
        let budget: Double
        let spent: Double?
        let note: String?
        let isToday: Bool
        let isFuture: Bool

        var delta: Double? {
            guard let spent else { return nil }
            return budget - spent
        }
    }

    let rows: [Row]
    let monthlyBudget: Double
    let totalSpent: Double
    let remaining: Double

    init(cycle: BudgetCycle, today: Date = Date(), calendar: Calendar = .current) {
        self.monthlyBudget = cycle.monthlyBudget
        self.totalSpent = cycle.totalSpent
        self.remaining = cycle.monthlyBudget - cycle.totalSpent

        let start = cycle.cycleStartDate
        let end = BudgetCalculator.cycleEnd(cycleStart: start, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: today)

        var rows: [Row] = []
        var day = calendar.startOfDay(for: start)
        while day <= end {
            let entry = cycle.entry(for: day, calendar: calendar)
            // Use the captured snapshot for logged days; project for the rest.
            let budget: Double
            if let entry {
                budget = entry.dailyBudgetAtTime
            } else {
                budget = BudgetCalculator.todaysBudget(
                    monthlyBudget: cycle.monthlyBudget,
                    spentBeforeToday: cycle.spentBefore(day, calendar: calendar),
                    totalSpent: cycle.totalSpent,
                    today: day,
                    cycleStart: start,
                    calendar: calendar
                ).available
            }

            rows.append(
                Row(
                    id: day,
                    date: day,
                    budget: budget,
                    spent: entry?.amountSpent,
                    note: entry?.note,
                    isToday: day == startOfToday,
                    isFuture: day > startOfToday
                )
            )

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        self.rows = rows
    }
}
