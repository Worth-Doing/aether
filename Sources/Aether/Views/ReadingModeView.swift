import SwiftUI
import AetherCore
import AetherUI
import BrowserEngine

/// Beautiful distraction-free reading mode with premium typography
struct ReadingModeView: View {
    let title: String
    let url: URL?
    let content: String
    let onDismiss: () -> Void

    @State private var fontSize: CGFloat = 17
    @State private var lineSpacing: CGFloat = 8
    @State private var maxWidth: CGFloat = 680
    @State private var showControls = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            AetherTheme.Colors.surface
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 60)

                    // Article header
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                        if let host = url?.host() {
                            Text(host.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(AetherTheme.Colors.accent)
                                .tracking(1)
                        }

                        Text(title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AetherTheme.Colors.textPrimary)
                            .lineSpacing(4)

                        Divider()
                            .background(AetherTheme.Colors.glassBorderSubtle)
                            .padding(.top, AetherTheme.Spacing.md)
                    }
                    .padding(.bottom, AetherTheme.Spacing.xxxl)

                    // Article body
                    Text(content)
                        .font(.system(size: fontSize, weight: .regular, design: .serif))
                        .foregroundColor(AetherTheme.Colors.textPrimary.opacity(0.85))
                        .lineSpacing(lineSpacing)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: maxWidth)
                .padding(.horizontal, AetherTheme.Spacing.xxxxl)
                .frame(maxWidth: .infinity)
            }

            // Floating controls
            VStack(spacing: AetherTheme.Spacing.md) {
                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(AetherTheme.Colors.glassSurface)
                                .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 8, y: 2)
                        )
                }
                .buttonStyle(.plain)

                // Typography controls toggle
                Button(action: { withAnimation(AetherTheme.Animation.spring) { showControls.toggle() } }) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(showControls ? AetherTheme.Colors.accentSubtle : AetherTheme.Colors.glassSurface)
                                .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 8, y: 2)
                        )
                }
                .buttonStyle(.plain)

                if showControls {
                    typographyControls
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(AetherTheme.Spacing.xl)
        }
    }

    private var typographyControls: some View {
        VStack(spacing: AetherTheme.Spacing.lg) {
            // Font size
            VStack(spacing: AetherTheme.Spacing.sm) {
                Text("Size")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AetherTheme.Colors.textTertiary)

                HStack(spacing: AetherTheme.Spacing.md) {
                    controlButton("minus") { fontSize = max(13, fontSize - 1) }
                    Text("\(Int(fontSize))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .frame(width: 22)
                    controlButton("plus") { fontSize = min(24, fontSize + 1) }
                }
            }

            Divider().frame(width: 40)

            // Width
            VStack(spacing: AetherTheme.Spacing.sm) {
                Text("Width")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AetherTheme.Colors.textTertiary)

                HStack(spacing: AetherTheme.Spacing.md) {
                    controlButton("arrow.left.and.right.circle") { maxWidth = max(500, maxWidth - 40) }
                    controlButton("arrow.left.and.right.circle.fill") { maxWidth = min(900, maxWidth + 40) }
                }
            }

            Divider().frame(width: 40)

            // Spacing
            VStack(spacing: AetherTheme.Spacing.sm) {
                Text("Spacing")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AetherTheme.Colors.textTertiary)

                HStack(spacing: AetherTheme.Spacing.md) {
                    controlButton("line.3.horizontal.decrease") { lineSpacing = max(4, lineSpacing - 2) }
                    controlButton("line.3.horizontal") { lineSpacing = min(14, lineSpacing + 2) }
                }
            }
        }
        .padding(AetherTheme.Spacing.lg)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                AetherTheme.Colors.glassCard.opacity(0.6)
            }
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .strokeBorder(AetherTheme.Colors.glassBorderSubtle, lineWidth: 0.5)
        )
        .shadow(color: AetherTheme.Colors.shadowColor, radius: 16, y: 4)
    }

    private func controlButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: AetherTheme.Radius.sm, style: .continuous)
                        .fill(AetherTheme.Colors.surfaceElevated)
                )
        }
        .buttonStyle(.plain)
    }
}
