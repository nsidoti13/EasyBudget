import SwiftUI
import SwiftData

/// Coordinates the 4-step onboarding and writes the initial `BudgetCycle`.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService

    enum Step: Int, CaseIterable {
        case welcome, budget, resetDate, notifications
    }

    @State private var step: Step = .welcome

    // Draft values collected across the steps.
    @State private var monthlyBudget: Double = 3_000
    @State private var resetDay: Int = 1
    @State private var notificationsEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            ProgressDots(count: Step.allCases.count, index: step.rawValue)
                .padding(.top, 12)

            content
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.snappy, value: step)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            WelcomeView { advance() }
        case .budget:
            SetBudgetView(monthlyBudget: $monthlyBudget) { advance() }
        case .resetDate:
            SetResetDateView(resetDay: $resetDay) { advance() }
        case .notifications:
            NotificationPermissionView(
                onEnable: {
                    notificationsEnabled = await notifications.requestAuthorization()
                    finish()
                },
                onSkip: {
                    notificationsEnabled = false
                    finish()
                }
            )
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    private func finish() {
        let start = BudgetCalculator.cycleStart(for: Date(), resetDay: resetDay)
        let cycle = BudgetCycle(
            monthlyBudget: monthlyBudget,
            resetDay: resetDay,
            cycleStartDate: start,
            notificationsEnabled: notificationsEnabled
        )
        context.insert(cycle)
        try? context.save()
        notifications.reschedule(for: cycle)
    }
}

/// Small page indicator used at the top of onboarding.
private struct ProgressDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(.snappy, value: index)
            }
        }
    }
}
