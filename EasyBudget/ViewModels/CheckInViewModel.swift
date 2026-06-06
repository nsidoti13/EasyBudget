import Foundation
import SwiftData
import Observation

/// Drives the daily check-in: input state, persistence, and the result message.
@MainActor
@Observable
final class CheckInViewModel {
    var amount: Double = 0
    var note: String = ""

    /// The result of the most recent confirm, used to show the result card.
    enum Result: Equatable {
        case under(saved: Double, daysRemaining: Int)
        case over(amount: Double)

        var headline: String {
            switch self {
            case .under(let saved, let days):
                let dayWord = days == 1 ? "day" : "days"
                if days <= 0 {
                    return "Nice. You saved \(saved.asCurrency)."
                }
                return "Nice. You saved \(saved.asCurrency) — spread across your remaining \(days) \(dayWord)."
            case .over(let amount):
                return "You went \(amount.asCurrency) over. Adjusting your daily budget for the rest of the month."
            }
        }

        var isOver: Bool { if case .over = self { return true }; return false }
    }

    private(set) var result: Result?

    private let cycle: BudgetCycle
    private let today: Date
    private let calendar: Calendar

    init(cycle: BudgetCycle, today: Date = Date(), calendar: Calendar = .current) {
        self.cycle = cycle
        self.today = today
        self.calendar = calendar

        // Pre-fill if today was already logged (lets the user correct it).
        if let existing = cycle.entry(for: today, calendar: calendar) {
            amount = existing.amountSpent
            note = existing.note ?? ""
        }
    }

    /// Today's available number, computed from spending before today.
    var todaysAvailable: Double {
        BudgetCalculator.todaysBudget(
            monthlyBudget: cycle.monthlyBudget,
            spentBeforeToday: cycle.spentBefore(today, calendar: calendar),
            totalSpent: cycle.totalSpent,
            today: today,
            cycleStart: cycle.cycleStartDate,
            calendar: calendar
        ).available
    }

    /// Persists the entry and computes the result card. Returns the result.
    @discardableResult
    func confirm(in context: ModelContext) -> Result {
        let available = todaysAvailable
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = cycle.entry(for: today, calendar: calendar) {
            existing.amountSpent = amount
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
            existing.dailyBudgetAtTime = available
        } else {
            let entry = DailyEntry(
                date: calendar.startOfDay(for: today),
                amountSpent: amount,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                dailyBudgetAtTime: available,
                cycle: cycle
            )
            // Setting `cycle` on the entry maintains the inverse relationship;
            // inserting registers it with the context.
            context.insert(entry)
        }
        try? context.save()

        // Redistribute across remaining days *after* today.
        let daysAfterToday = max(
            BudgetCalculator.daysRemaining(from: today, cycleStart: cycle.cycleStartDate, calendar: calendar) - 1,
            0
        )
        let difference = available - amount
        let outcome: Result = difference >= 0
            ? .under(saved: difference, daysRemaining: daysAfterToday)
            : .over(amount: -difference)

        result = outcome

        // Keep the morning notifications in sync with the new spending.
        NotificationService.shared.reschedule(for: cycle)
        return outcome
    }
}
