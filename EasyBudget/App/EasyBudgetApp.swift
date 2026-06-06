import SwiftUI
import SwiftData

@main
struct EasyBudgetApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: BudgetCycle.self, DailyEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(NotificationService.shared)
        }
        .modelContainer(container)
    }
}
