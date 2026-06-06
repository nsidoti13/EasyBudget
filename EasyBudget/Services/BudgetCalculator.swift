import Foundation

/// The result of computing today's available spending.
struct DailyBudget: Equatable {
    /// The amount available to spend today, clamped to never go below zero (for display).
    var available: Double
    /// The unclamped value — can be negative when the cycle is in deficit.
    var raw: Double
    /// monthlyBudget minus everything spent so far this cycle (can be negative).
    var remainingThisMonth: Double
    /// Days left in the cycle, including today.
    var daysRemaining: Int
    /// Total days in the full cycle.
    var totalDaysInCycle: Int
    /// Total spent this cycle so far.
    var totalSpent: Double

    var isOverBudget: Bool { remainingThisMonth < 0 }
    var isUnderBudget: Bool { remainingThisMonth > 0 }
}

/// Pure budgeting math. No SwiftData, no UI — fully testable in isolation.
///
/// Cycle model: a cycle starts on `resetDay` and ends the day before the next
/// `resetDay`. "Days remaining" always includes today, because you can still
/// spend today.
enum BudgetCalculator {

    // MARK: - Cycle boundaries

    /// The most recent reset date on or before `date`.
    static func cycleStart(
        for date: Date,
        resetDay: Int,
        calendar: Calendar = .current
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        var comps = calendar.dateComponents([.year, .month], from: startOfDay)
        comps.day = resetDay
        guard let candidate = calendar.date(from: comps) else { return startOfDay }

        if candidate <= startOfDay {
            return candidate
        }
        // Reset day hasn't happened yet this month — use last month's reset day.
        return calendar.date(byAdding: .month, value: -1, to: candidate) ?? candidate
    }

    /// The next reset date strictly after the given cycle start.
    /// Because `resetDay` is constrained to 1–28, adding one month preserves the day.
    static func nextResetDate(
        afterCycleStart start: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: .month, value: 1, to: start) ?? start
    }

    /// The last day a user can spend within the cycle (day before next reset).
    static func cycleEnd(
        cycleStart start: Date,
        calendar: Calendar = .current
    ) -> Date {
        let next = nextResetDate(afterCycleStart: start, calendar: calendar)
        return calendar.date(byAdding: .day, value: -1, to: next) ?? start
    }

    /// Total number of days in the cycle.
    static func totalDays(
        cycleStart start: Date,
        calendar: Calendar = .current
    ) -> Int {
        let next = nextResetDate(afterCycleStart: start, calendar: calendar)
        let days = calendar.dateComponents([.day], from: start, to: next).day ?? 30
        return max(days, 1)
    }

    /// Days remaining in the cycle, including `today`.
    static func daysRemaining(
        from today: Date,
        cycleStart start: Date,
        calendar: Calendar = .current
    ) -> Int {
        let next = nextResetDate(afterCycleStart: start, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: today)
        let days = calendar.dateComponents([.day], from: startOfToday, to: next).day ?? 0
        return max(days, 0)
    }

    /// Whether `today` falls inside the cycle that began on `start`.
    static func isWithinCycle(
        _ today: Date,
        cycleStart start: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let startOfToday = calendar.startOfDay(for: today)
        let next = nextResetDate(afterCycleStart: start, calendar: calendar)
        return startOfToday >= start && startOfToday < next
    }

    // MARK: - Daily budget

    /// Computes today's available number.
    ///
    /// - Parameters:
    ///   - monthlyBudget: the full monthly budget.
    ///   - spentBeforeToday: total spent on days strictly before today.
    ///   - totalSpent: total spent this cycle (including today, for "remaining this month").
    ///   - today: the current date.
    ///   - cycleStart: the active cycle's start date.
    ///
    /// Today's number is intentionally derived from spending *before* today so it
    /// stays stable across the day; logging today's spend redistributes the
    /// difference across the remaining days automatically.
    static func todaysBudget(
        monthlyBudget: Double,
        spentBeforeToday: Double,
        totalSpent: Double,
        today: Date,
        cycleStart start: Date,
        calendar: Calendar = .current
    ) -> DailyBudget {
        let days = max(daysRemaining(from: today, cycleStart: start, calendar: calendar), 1)
        let remainingBeforeToday = monthlyBudget - spentBeforeToday
        let raw = remainingBeforeToday / Double(days)

        return DailyBudget(
            available: max(raw, 0),
            raw: raw,
            remainingThisMonth: monthlyBudget - totalSpent,
            daysRemaining: days,
            totalDaysInCycle: totalDays(cycleStart: start, calendar: calendar),
            totalSpent: totalSpent
        )
    }
}
