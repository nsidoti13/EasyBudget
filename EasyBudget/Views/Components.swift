import SwiftUI

/// Full-width, prominent primary action button.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? tint : Color.secondary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Subtle secondary text button.
struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// A large, tappable currency input. Shows "$" alongside a big editable number.
struct CurrencyField: View {
    @Binding var amount: Double
    var tint: Color = .accentColor
    var autofocus: Bool = true

    @FocusState private var focused: Bool
    @State private var text: String = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("$")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            TextField("0", text: $text)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .fixedSize()
                .focused($focused)
                .onChange(of: text) { _, newValue in
                    let filtered = sanitize(newValue)
                    if filtered != newValue { text = filtered }
                    amount = Double(filtered) ?? 0
                }
        }
        .onAppear {
            text = initialText(for: amount)
            if autofocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    private func initialText(for value: Double) -> String {
        guard value > 0 else { return "" }
        return value == value.rounded() ? String(Int(value)) : String(value)
    }

    /// Keep only digits and a single decimal point, max two fraction digits.
    private func sanitize(_ input: String) -> String {
        var result = ""
        var seenDot = false
        var fractionDigits = 0
        for char in input {
            if char.isNumber {
                if seenDot {
                    if fractionDigits >= 2 { continue }
                    fractionDigits += 1
                }
                result.append(char)
            } else if (char == "." || char == ",") && !seenDot {
                seenDot = true
                result.append(".")
            }
        }
        return result
    }
}

/// Centered onboarding scaffold: a hero area on top and pinned actions at bottom.
struct OnboardingScaffold<Hero: View, Actions: View>: View {
    @ViewBuilder var hero: Hero
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            hero
            Spacer(minLength: 0)
            actions
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
