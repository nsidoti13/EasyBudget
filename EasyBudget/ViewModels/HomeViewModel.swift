import Foundation

/// Derives all of the home screen's display values from a cycle for a given day.
/// Pure and value-typed — recomputed whenever the underlying SwiftData changes.
struct HomeViewModel {
    let budget: DailyBudget
    let today: Date
    let resetDay: Int

    init(cycle: BudgetCycle, today: Date = Date(), calendar: Calendar = .current) {
        self.today = today
        self.resetDay = cycle.resetDay
        self.budget = BudgetCalculator.todaysBudget(
            monthlyBudget: cycle.monthlyBudget,
            spentBeforeToday: cycle.spentBefore(today, calendar: calendar),
            totalSpent: cycle.totalSpent,
            today: today,
            cycleStart: cycle.cycleStartDate,
            calendar: calendar
        )
    }

    var state: BudgetState { BudgetState(budget) }

    var dateLine: String { Formatters.weekdayLong.string(from: today) }

    var availableNumber: String { budget.available.asCurrency }

    var daysLeftText: String {
        let days = budget.daysRemaining
        let dayWord = days == 1 ? "day" : "days"
        return "\(days) \(dayWord) left in cycle"
    }

    var remainingText: String {
        let remaining = max(budget.remainingThisMonth, 0)
        return "\(remaining.asCurrency) remaining this month"
    }

    var secondaryLine: String {
        "\(daysLeftText) · \(remainingText)"
    }

    /// Shown only when the cycle is in deficit.
    var deficitMessage: String? {
        guard budget.isOverBudget else { return nil }
        return "You're \(abs(budget.remainingThisMonth).asCurrency) over for this cycle. Daily budget stays at $0 until the next reset."
    }
}
