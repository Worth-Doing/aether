import SwiftUI

public struct AetherTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var onSubmit: (() -> Void)?

    public init(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.onSubmit = onSubmit
    }

    public var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .onSubmit { onSubmit?() }
            } else {
                TextField(placeholder, text: $text)
                    .onSubmit { onSubmit?() }
            }
        }
        .textFieldStyle(.plain)
        .font(AetherTheme.Typography.body)
        .foregroundColor(AetherTheme.Colors.textPrimary)
        .padding(.horizontal, AetherTheme.Spacing.lg)
        .padding(.vertical, AetherTheme.Spacing.md)
        .background(AetherTheme.Colors.surface)
        .cornerRadius(AetherTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.md)
                .strokeBorder(AetherTheme.Colors.border, lineWidth: 1)
        )
    }
}
