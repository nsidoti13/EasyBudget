import SwiftUI
import SwiftData

/// Decides between onboarding and the main app, and keeps the cycle fresh on
/// every launch / foreground.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService
    @Environment(\.scenePhase) private var scenePhase

    @Query private var cycles: [BudgetCycle]

    private var cycle: BudgetCycle? { cycles.first }

    var body: some View {
        Group {
            if let cycle {
                HomeView(cycle: cycle)
            } else {
                OnboardingFlow()
            }
        }
        .onAppear { refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .task { await notifications.refreshAuthorizationStatus() }
    }

    /// Runs the recalculation triggers described in the spec: on app launch and
    /// when a new day has begun (cycle rollover).
    private func refresh() {
        guard let cycle else { return }
        CycleManager.rollIfNeeded(cycle, in: context)
        notifications.reschedule(for: cycle)
    }
}
