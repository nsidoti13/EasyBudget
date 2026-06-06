import Foundation
import SwiftData

/// The user's budgeting configuration and the currently active spending cycle.
///
/// Phase 1 keeps a single `BudgetCycle` on device. When the reset day comes
/// around (or the user resets manually) the entries are cleared and
/// `cycleStartDate` advances — the budget and notification preferences persist.
@Model
final class BudgetCycle {
    var id: UUID
    var monthlyBudget: Double
    /// Day of the month (1–28) the cycle resets — payday / billing cycle start.
    var resetDay: Int
    var createdAt: Date
    /// Start date of the currently active cycle (normalized to start of day).
    var cycleStartDate: Date

    // Notification preferences live alongside the cycle so there is a single
    // local source of truth. They survive a cycle reset.
    var notificationsEnabled: Bool
    var morningHour: Int
    var morningMinute: Int
    var eveningHour: Int
    var eveningMinute: Int

    @Relationship(deleteRule: .cascade, inverse: \DailyEntry.cycle)
    var entries: [DailyEntry] = []

    init(
        id: UUID = UUID(),
        monthlyBudget: Double,
        resetDay: Int,
        createdAt: Date = Date(),
        cycleStartDate: Date,
        notificationsEnabled: Bool = false,
        morningHour: Int = 8,
        morningMinute: Int = 0,
        eveningHour: Int = 21,
        eveningMinute: Int = 0
    ) {
        self.id = id
        self.monthlyBudget = monthlyBudget
        self.resetDay = resetDay
        self.createdAt = createdAt
        self.cycleStartDate = cycleStartDate
        self.notificationsEnabled = notificationsEnabled
        self.morningHour = morningHour
        self.morningMinute = morningMinute
        self.eveningHour = eveningHour
        self.eveningMinute = eveningMinute
    }
}

extension BudgetCycle {
    /// Total amount spent across all logged entries in the active cycle.
    var totalSpent: Double {
        entries.reduce(0) { $0 + $1.amountSpent }
    }

    /// Amount spent on entries dated strictly before the given day.
    func spentBefore(_ day: Date, calendar: Calendar = .current) -> Double {
        let startOfDay = calendar.startOfDay(for: day)
        return entries
            .filter { calendar.startOfDay(for: $0.date) < startOfDay }
            .reduce(0) { $0 + $1.amountSpent }
    }

    /// The entry logged for the given day, if any.
    func entry(for day: Date, calendar: Calendar = .current) -> DailyEntry? {
        let target = calendar.startOfDay(for: day)
        return entries.first { calendar.startOfDay(for: $0.date) == target }
    }
}
