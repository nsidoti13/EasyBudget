import Foundation
import SwiftData

/// Owns cycle lifecycle concerns: rolling a finished cycle forward and manual resets.
enum CycleManager {

    /// If `now` has moved past the active cycle, advance to the cycle that
    /// contains today and clear the previous cycle's entries. Keeps the budget
    /// amount, reset day, and notification preferences intact.
    ///
    /// - Returns: `true` if a roll occurred (caller may want to reschedule notifications).
    @discardableResult
    static func rollIfNeeded(
        _ cycle: BudgetCycle,
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard !BudgetCalculator.isWithinCycle(now, cycleStart: cycle.cycleStartDate, calendar: calendar) else {
            return false
        }
        let newStart = BudgetCalculator.cycleStart(for: now, resetDay: cycle.resetDay, calendar: calendar)
        guard newStart != cycle.cycleStartDate else { return false }

        clearEntries(cycle, in: context)
        cycle.cycleStartDate = newStart
        try? context.save()
        return true
    }

    /// Manual "Reset this cycle" — clears entries and restarts at the current
    /// cycle start for the configured reset day.
    static func resetCurrentCycle(
        _ cycle: BudgetCycle,
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        clearEntries(cycle, in: context)
        cycle.cycleStartDate = BudgetCalculator.cycleStart(for: now, resetDay: cycle.resetDay, calendar: calendar)
        try? context.save()
    }

    private static func clearEntries(_ cycle: BudgetCycle, in context: ModelContext) {
        for entry in cycle.entries {
            context.delete(entry)
        }
        cycle.entries.removeAll()
    }
}
