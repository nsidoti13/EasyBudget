import SwiftUI

struct SetBudgetView: View {
    @Binding var monthlyBudget: Double
    var onContinue: () -> Void

    var body: some View {
        OnboardingScaffold {
            VStack(spacing: 16) {
                Text("What's your monthly budget?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("The total you want to spend each cycle.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                CurrencyField(amount: $monthlyBudget)
                    .padding(.top, 24)
            }
        } actions: {
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle(enabled: monthlyBudget > 0))
                .disabled(monthlyBudget <= 0)
        }
    }
}

#Preview {
    SetBudgetView(monthlyBudget: .constant(3000), onContinue: {})
}
