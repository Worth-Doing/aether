import SwiftUI
import AetherCore
import AetherUI
import AIService
import SecureStorage

public struct OnboardingView: View {
    @State private var currentStep: Step = .welcome
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var validationError: String?
    @State private var keyIsValid: Bool = false

    let openRouterClient: OpenRouterClient
    let onComplete: () -> Void

    public init(openRouterClient: OpenRouterClient, onComplete: @escaping () -> Void) {
        self.openRouterClient = openRouterClient
        self.onComplete = onComplete
    }

    enum Step: Int, CaseIterable {
        case welcome
        case features
        case aiSetup
        case ready
    }

    public var body: some View {
        ZStack {
            AetherTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: AetherTheme.Spacing.md) {
                    ForEach(Step.allCases, id: \.rawValue) { step in
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue
                                  ? AetherTheme.Colors.accent
                                  : AetherTheme.Colors.surfaceElevated)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, AetherTheme.Spacing.xxl)

                Spacer()

                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeStep
                    case .features:
                        featuresStep
                    case .aiSetup:
                        aiSetupStep
                    case .ready:
                        readyStep
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
            .frame(maxWidth: 520)
            .padding(AetherTheme.Spacing.xxxl)
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.accentGlow)
                    .frame(width: 100, height: 100)
                    .blur(radius: 25)

                Image(systemName: "globe.desk")
                    .font(.system(size: 50, weight: .thin))
                    .foregroundColor(AetherTheme.Colors.accent)
            }

            Text("Aether")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(AetherTheme.Colors.textPrimary)

            Text("A cognitive browser for macOS")
                .font(AetherTheme.Typography.title)
                .foregroundColor(AetherTheme.Colors.textSecondary)

            Text("Browse, organize, and remember.\nAether helps you think better on the web.")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            AetherButton("Get Started") {
                withAnimation(AetherTheme.Animation.standard) {
                    currentStep = .features
                }
            }
            .padding(.top, AetherTheme.Spacing.xl)
        }
    }

    // MARK: - Features

    private var featuresStep: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Text("Built for deep work")
                .font(AetherTheme.Typography.title)
                .foregroundColor(AetherTheme.Colors.textPrimary)

            VStack(spacing: AetherTheme.Spacing.xl) {
                featureCard(
                    icon: "rectangle.split.3x1",
                    title: "Multi-Panel Browsing",
                    description: "Split your view into multiple panels for research and comparison."
                )
                featureCard(
                    icon: "tray.2",
                    title: "Workspaces",
                    description: "Save and restore browsing sessions by project or topic."
                )
                featureCard(
                    icon: "brain",
                    title: "AI-Powered Assist",
                    description: "Summarize pages, extract key points, and chat about content."
                )
            }

            AetherButton("Continue") {
                withAnimation(AetherTheme.Animation.standard) {
                    currentStep = .aiSetup
                }
            }
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AetherTheme.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AetherTheme.Colors.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: AetherTheme.Spacing.xs) {
                Text(title)
                    .font(AetherTheme.Typography.bodyMedium)
                    .foregroundColor(AetherTheme.Colors.textPrimary)
                Text(description)
                    .font(AetherTheme.Typography.caption)
                    .foregroundColor(AetherTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AetherTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .fill(AetherTheme.Colors.glassCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .strokeBorder(AetherTheme.Colors.glassBorder, lineWidth: 0.5)
        )
        .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 8, x: 0, y: 2)
    }

    // MARK: - AI Setup

    private var aiSetupStep: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            Text("AI Features (Optional)")
                .font(AetherTheme.Typography.title)
                .foregroundColor(AetherTheme.Colors.textPrimary)

            Text("Aether uses OpenRouter for AI features like page summarization and semantic search. You can configure this now or later in Settings.")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                Text("OpenRouter API Key")
                    .font(AetherTheme.Typography.captionMedium)
                    .foregroundColor(AetherTheme.Colors.textSecondary)

                AetherTextField("sk-or-...", text: $apiKey, isSecure: true)

                if let error = validationError {
                    Text(error)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.error)
                }

                if keyIsValid {
                    HStack(spacing: AetherTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AetherTheme.Colors.success)
                        Text("API key validated successfully")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.success)
                    }
                }
            }

            HStack(spacing: AetherTheme.Spacing.lg) {
                AetherButton("Skip for now", style: .secondary) {
                    withAnimation(AetherTheme.Animation.standard) {
                        currentStep = .ready
                    }
                }

                if !apiKey.isEmpty {
                    AetherButton(isValidating ? "Validating..." : "Validate & Continue") {
                        validateKey()
                    }
                }
            }
        }
    }

    private func validateKey() {
        isValidating = true
        validationError = nil

        Task {
            do {
                let valid = try await openRouterClient.validateAPIKey(apiKey)
                await MainActor.run {
                    isValidating = false
                    if valid {
                        try? openRouterClient.setAPIKey(apiKey)
                        keyIsValid = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(AetherTheme.Animation.standard) {
                                currentStep = .ready
                            }
                        }
                    } else {
                        validationError = "Invalid API key. Please check and try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationError = "Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Ready

    private var readyStep: some View {
        VStack(spacing: AetherTheme.Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(AetherTheme.Colors.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 42, weight: .thin))
                    .foregroundColor(AetherTheme.Colors.success)
            }

            Text("You're all set")
                .font(AetherTheme.Typography.title)
                .foregroundColor(AetherTheme.Colors.textPrimary)

            Text("Aether is ready. Start browsing.")
                .font(AetherTheme.Typography.body)
                .foregroundColor(AetherTheme.Colors.textSecondary)

            VStack(spacing: AetherTheme.Spacing.md) {
                shortcutInfo("Cmd+L", "Focus address bar")
                shortcutInfo("Cmd+K", "Command palette")
                shortcutInfo("Cmd+T", "New tab")
                shortcutInfo("Cmd+\\", "Split panel")
            }
            .padding(.top, AetherTheme.Spacing.md)

            AetherButton("Launch Aether") {
                onComplete()
            }
            .padding(.top, AetherTheme.Spacing.xl)
        }
    }

    private func shortcutInfo(_ key: String, _ description: String) -> some View {
        HStack(spacing: AetherTheme.Spacing.lg) {
            Text(key)
                .font(AetherTheme.Typography.shortcut)
                .foregroundColor(AetherTheme.Colors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AetherTheme.Colors.glassSurface)
                .cornerRadius(AetherTheme.Radius.sm)
                .frame(width: 70, alignment: .trailing)

            Text(description)
                .font(AetherTheme.Typography.caption)
                .foregroundColor(AetherTheme.Colors.textTertiary)
        }
    }
}
