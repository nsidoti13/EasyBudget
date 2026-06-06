import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var notifications: NotificationService

    let cycle: BudgetCycle

    @State private var showingCheckIn = false
    @State private var showingMonth = false
    @State private var showingSettings = false

    private var vm: HomeViewModel { HomeViewModel(cycle: cycle) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $showingCheckIn) {
                CheckInSheet(cycle: cycle)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(cycle: cycle)
            }
            .navigationDestination(isPresented: $showingMonth) {
                MonthView(cycle: cycle)
            }
            .onChange(of: notifications.pendingRoute) { _, route in
                handle(route)
            }
            .onAppear { handle(notifications.pendingRoute) }
        }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(spacing: 14) {
            Text(vm.dateLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Available today")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Text(vm.availableNumber)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .foregroundStyle(vm.state.accent)
                .contentTransition(.numericText())
                .animation(.snappy, value: vm.availableNumber)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(vm.secondaryLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let deficit = vm.deficitMessage {
                Text(deficit)
                    .font(.footnote)
                    .foregroundStyle(Theme.over)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(vm.state.tint, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Button {
                showingCheckIn = true
            } label: {
                Label("Log today's spending", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: vm.state.accent))

            Button("View this month") {
                showingMonth = true
            }
            .buttonStyle(QuietButtonStyle())
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [vm.state.accent.opacity(0.06), Color.clear],
            startPoint: .top,
            endPoint: .center
        )
    }

    // MARK: - Notification routing

    private func handle(_ route: NotificationService.Route?) {
        guard let route else { return }
        switch route {
        case .checkIn: showingCheckIn = true
        case .home: break
        }
        notifications.pendingRoute = nil
    }
}
