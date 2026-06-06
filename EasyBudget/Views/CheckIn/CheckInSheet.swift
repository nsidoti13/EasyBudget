import SwiftUI
import SwiftData
import UIKit

struct CheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let cycle: BudgetCycle

    @State private var vm: CheckInViewModel
    @State private var result: CheckInViewModel.Result?

    init(cycle: BudgetCycle) {
        self.cycle = cycle
        _vm = State(initialValue: CheckInViewModel(cycle: cycle))
    }

    var body: some View {
        NavigationStack {
            Group {
                if let result {
                    resultCard(result)
                } else {
                    inputForm
                }
            }
            .navigationTitle(result == nil ? "Today's spending" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if result == nil {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Input

    private var inputForm: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("How much did you spend today?")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Today's budget was \(vm.todaysAvailable.asCurrency)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            CurrencyField(amount: $vm.amount)
                .padding(.vertical, 8)

            TextField("Note (optional) — e.g. groceries + gas", text: $vm.note)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Spacer()

            Button("Done") {
                let outcome = vm.confirm(in: context)
                withAnimation(.snappy) { result = outcome }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(outcome.isOver ? .warning : .success)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Result

    private func resultCard(_ result: CheckInViewModel.Result) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: result.isOver ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(result.isOver ? Theme.over : Theme.under)
                .symbolRenderingMode(.hierarchical)

            Text(result.headline)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle(tint: result.isOver ? Theme.over : Theme.under))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
