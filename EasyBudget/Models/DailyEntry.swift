import Foundation
import SwiftData

/// A single day's logged spending within a `BudgetCycle`.
@Model
final class DailyEntry {
    var id: UUID
    /// Normalized to the start of the day this entry represents.
    var date: Date
    var amountSpent: Double
    var note: String?
    /// Snapshot of what the daily budget was on this day, captured at log time.
    var dailyBudgetAtTime: Double

    var cycle: BudgetCycle?

    init(
        id: UUID = UUID(),
        date: Date,
        amountSpent: Double,
        note: String? = nil,
        dailyBudgetAtTime: Double,
        cycle: BudgetCycle? = nil
    ) {
        self.id = id
        self.date = date
        self.amountSpent = amountSpent
        self.note = note
        self.dailyBudgetAtTime = dailyBudgetAtTime
        self.cycle = cycle
    }
}
