import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notifications: NotificationService

    @Bindable var cycle: BudgetCycle

    @State private var showingBudgetEditor = false
    @State private var draftBudget: Double = 0

    @State private var showingResetDayConfirm = false
    @State private var pendingResetDay: Int?

    @State private var showingCycleResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                budgetSection
                cycleSection
                notificationSection
                dangerSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) { budgetEditor }
            .alert("Change reset day?", isPresented: $showingResetDayConfirm) {
                Button("Cancel", role: .cancel) { pendingResetDay = nil }
                Button("Change & restart", role: .destructive) { applyResetDayChange() }
            } message: {
                Text("Changing this will restart your current cycle and clear this cycle's entries.")
            }
            .alert("Reset this cycle?", isPresented: $showingCycleResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetCycle() }
            } message: {
                Text("This clears all spending logged this cycle. Your budget and reset day stay the same.")
            }
        }
    }

    // MARK: - Sections

    private var budgetSection: some View {
        Section("Budget") {
            Button {
                draftBudget = cycle.monthlyBudget
                showingBudgetEditor = true
            } label: {
                HStack {
                    Text("Monthly budget").foregroundStyle(.primary)
                    Spacer()
                    Text(cycle.monthlyBudget.asCurrency).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var cycleSection: some View {
        Section {
            Picker("Reset day", selection: Binding(
                get: { cycle.resetDay },
                set: { newValue in
                    if newValue != cycle.resetDay {
                        pendingResetDay = newValue
                        showingResetDayConfirm = true
                    }
                }
            )) {
                ForEach(1...28, id: \.self) { day in
                    Text(ordinal(day)).tag(day)
                }
            }
        } header: {
            Text("Cycle")
        } footer: {
            Text("Changing this will restart your current cycle.")
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("Notifications", isOn: Binding(
                get: { cycle.notificationsEnabled },
                set: { toggleNotifications($0) }
            ))

            if cycle.notificationsEnabled {
                DatePicker("Morning reminder", selection: morningBinding, displayedComponents: .hourAndMinute)
                DatePicker("Evening reminder", selection: eveningBinding, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Reminders")
        } footer: {
            if notifications.authorizationStatus == .denied {
                Text("Notifications are turned off in iOS Settings. Enable them there to receive reminders.")
            } else {
                Text("Morning tells you today's number. Evening reminds you to log spending.")
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button("Reset this cycle", role: .destructive) {
                showingCycleResetConfirm = true
            }
        }
    }

    // MARK: - Budget editor

    private var budgetEditor: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Monthly budget")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 24)
                CurrencyField(amount: $draftBudget)
                Spacer()
                Button("Save") {
                    cycle.monthlyBudget = draftBudget
                    save()
                    showingBudgetEditor = false
                }
                .buttonStyle(PrimaryButtonStyle(enabled: draftBudget > 0))
                .disabled(draftBudget <= 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingBudgetEditor = false }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Bindings & actions

    private var morningBinding: Binding<Date> {
        timeBinding(hour: \.morningHour, minute: \.morningMinute)
    }

    private var eveningBinding: Binding<Date> {
        timeBinding(hour: \.eveningHour, minute: \.eveningMinute)
    }

    private func timeBinding(
        hour: ReferenceWritableKeyPath<BudgetCycle, Int>,
        minute: ReferenceWritableKeyPath<BudgetCycle, Int>
    ) -> Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = cycle[keyPath: hour]
                comps.minute = cycle[keyPath: minute]
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                cycle[keyPath: hour] = comps.hour ?? 8
                cycle[keyPath: minute] = comps.minute ?? 0
                save()
            }
        )
    }

    private func toggleNotifications(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notifications.requestAuthorization()
                cycle.notificationsEnabled = granted
                save()
            }
        } else {
            cycle.notificationsEnabled = false
            notifications.cancelAll()
            save(reschedule: false)
        }
    }

    private func applyResetDayChange() {
        guard let day = pendingResetDay else { return }
        cycle.resetDay = day
        CycleManager.resetCurrentCycle(cycle, in: context)
        pendingResetDay = nil
        save()
    }

    private func resetCycle() {
        CycleManager.resetCurrentCycle(cycle, in: context)
        save()
    }

    private func save(reschedule: Bool = true) {
        try? context.save()
        if reschedule {
            notifications.reschedule(for: cycle)
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}
