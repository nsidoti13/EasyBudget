import SwiftUI

struct NotificationPermissionView: View {
    var onEnable: () async -> Void
    var onSkip: () -> Void

    @State private var working = false

    var body: some View {
        OnboardingScaffold {
            VStack(spacing: 20) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .symbolRenderingMode(.hierarchical)

                Text("Daily reminders")
                    .font(.title.bold())

                Text("We'll send one gentle nudge each morning and evening.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 14) {
                    reminderRow(icon: "sunrise.fill", title: "Morning", detail: "“Today's budget: $94.00”")
                    reminderRow(icon: "moon.stars.fill", title: "Evening", detail: "“How much did you spend today?”")
                }
                .padding(20)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 8)
            }
        } actions: {
            VStack(spacing: 8) {
                Button {
                    working = true
                    Task {
                        await onEnable()
                        working = false
                    }
                } label: {
                    if working {
                        ProgressView().tint(.white)
                    } else {
                        Text("Enable notifications")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(working)

                Button("Not now", action: onSkip)
                    .buttonStyle(QuietButtonStyle())
                    .padding(.top, 4)
            }
        }
    }

    private func reminderRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionView(onEnable: {}, onSkip: {})
}
