import SwiftUI

struct SetResetDateView: View {
    @Binding var resetDay: Int
    var onContinue: () -> Void

    var body: some View {
        OnboardingScaffold {
            VStack(spacing: 16) {
                Text("When does your budget reset?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Payday or billing cycle start. Your spending resets on this day each month.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Picker("Reset day", selection: $resetDay) {
                    ForEach(1...28, id: \.self) { day in
                        Text(ordinal(day)).tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 180)
                .padding(.top, 8)

                Text("Resets on the \(ordinal(resetDay)) of every month.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
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

#Preview {
    SetResetDateView(resetDay: .constant(1), onContinue: {})
}
