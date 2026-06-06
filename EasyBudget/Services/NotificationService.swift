import Foundation
import UserNotifications

/// Schedules the morning ("today's budget") and evening ("how much did you
/// spend?") local notifications. No server involved — everything is computed
/// on-device with `UNUserNotificationCenter`.
@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    /// Routing target when a notification is tapped.
    enum Route: String {
        case home
        case checkIn
    }

    /// Set by the app delegate when a notification is tapped, observed by the UI.
    @Published var pendingRoute: Route?

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private static let morningPrefix = "morning."
    private static let eveningID = "evening.checkin"

    override private init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Cancels and re-schedules all notifications based on the current cycle state.
    /// Safe to call on launch and after every check-in / settings change.
    func reschedule(for cycle: BudgetCycle, now: Date = Date(), calendar: Calendar = .current) {
        cancelAll()
        guard cycle.notificationsEnabled else { return }

        scheduleMorningNotifications(for: cycle, now: now, calendar: calendar)
        scheduleEveningNotification(for: cycle)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    /// Schedules one morning notification per remaining day in the cycle, each
    /// with that day's projected budget baked in. Re-run daily on launch so the
    /// amounts stay accurate as real spending is logged.
    private func scheduleMorningNotifications(for cycle: BudgetCycle, now: Date, calendar: Calendar) {
        let cycleEnd = BudgetCalculator.cycleEnd(cycleStart: cycle.cycleStartDate, calendar: calendar)
        let startOfToday = calendar.startOfDay(for: now)
        let totalSpent = cycle.totalSpent

        // iOS caps pending requests at 64; a cycle is at most ~31 days.
        var day = startOfToday
        while day <= cycleEnd {
            let spentBefore = cycle.spentBefore(day, calendar: calendar)
            let budget = BudgetCalculator.todaysBudget(
                monthlyBudget: cycle.monthlyBudget,
                spentBeforeToday: spentBefore,
                totalSpent: totalSpent,
                today: day,
                cycleStart: cycle.cycleStartDate,
                calendar: calendar
            )

            var fireComps = calendar.dateComponents([.year, .month, .day], from: day)
            fireComps.hour = cycle.morningHour
            fireComps.minute = cycle.morningMinute

            // Skip a fire time that has already passed today.
            if let fireDate = calendar.date(from: fireComps), fireDate <= now {
                day = calendar.date(byAdding: .day, value: 1, to: day) ?? cycleEnd.addingTimeInterval(86_400)
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "Easy Budget"
            content.body = "Today's budget: \(budget.available.asCurrency)"
            content.sound = .default
            content.userInfo = ["route": Route.home.rawValue]

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComps, repeats: false)
            let id = Self.morningPrefix + ISO8601DateFormatter().string(from: day)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))

            day = calendar.date(byAdding: .day, value: 1, to: day) ?? cycleEnd.addingTimeInterval(86_400)
        }
    }

    /// A single repeating daily evening reminder.
    private func scheduleEveningNotification(for cycle: BudgetCycle) {
        let content = UNMutableNotificationContent()
        content.title = "Easy Budget"
        content.body = "How much did you spend today?"
        content.sound = .default
        content.userInfo = ["route": Route.checkIn.rawValue]

        var comps = DateComponents()
        comps.hour = cycle.eveningHour
        comps.minute = cycle.eveningMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.eveningID, content: content, trigger: trigger))
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    // Show banners even while the app is foregrounded.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let raw = response.notification.request.content.userInfo["route"] as? String
        Task { @MainActor in
            if let raw, let route = Route(rawValue: raw) {
                self.pendingRoute = route
            }
            completionHandler()
        }
    }
}
