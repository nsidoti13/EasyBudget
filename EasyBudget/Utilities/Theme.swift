import SwiftUI

/// The three calm visual states for the home screen. Never alarming red —
/// over-budget is a gentle amber.
enum BudgetState {
    case neutral
    case under
    case over

    init(_ budget: DailyBudget) {
        if budget.isOverBudget {
            self = .over
        } else if budget.isUnderBudget {
            self = .under
        } else {
            self = .neutral
        }
    }

    var accent: Color {
        switch self {
        case .neutral: return Theme.neutral
        case .under: return Theme.under
        case .over: return Theme.over
        }
    }

    /// A soft background tint behind the hero number.
    var tint: Color { accent.opacity(0.12) }
}

enum Theme {
    static let neutral = Color.accentColor
    static let under = Color(red: 0.30, green: 0.69, blue: 0.45)   // soft green
    static let over = Color(red: 0.90, green: 0.62, blue: 0.20)    // soft amber
}
