import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        OnboardingScaffold {
            VStack(spacing: 20) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)
                    .symbolRenderingMode(.hierarchical)

                Text("Easy Budget")
                    .font(.largeTitle.bold())

                Text("Know your number for today.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Set a monthly budget. Every morning we tell you exactly how much you can spend today — and adjust automatically as you go.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        } actions: {
            Button("Get started", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
