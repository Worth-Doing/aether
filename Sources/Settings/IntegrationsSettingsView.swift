import SwiftUI
import AetherCore
import AetherUI
import SecureStorage
import WebSearchService

/// Premium integrations settings view for API providers
public struct IntegrationsSettingsView: View {
    let searchManager: SearchManager
    let keychain: KeychainManager

    @State private var expandedProvider: SearchProviderType?
    @State private var apiKeys: [SearchProviderType: String] = [:]
    @State private var validationStates: [SearchProviderType: ValidationState] = [:]

    enum ValidationState: Equatable {
        case idle
        case validating
        case valid
        case invalid(String)
    }

    public init(searchManager: SearchManager, keychain: KeychainManager) {
        self.searchManager = searchManager
        self.keychain = keychain
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: AetherTheme.Spacing.xl) {
                // Header
                VStack(spacing: AetherTheme.Spacing.md) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(AetherTheme.Colors.accent)

                    Text("Search Integrations")
                        .font(AetherTheme.Typography.title)
                        .foregroundColor(AetherTheme.Colors.textPrimary)

                    Text("Connect search APIs to unlock powerful web intelligence.\nAether uses these services to deliver deeper, smarter search results.")
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, AetherTheme.Spacing.lg)
                .padding(.bottom, AetherTheme.Spacing.md)

                // Provider cards
                ForEach(SearchProviderType.allCases) { provider in
                    ProviderCard(
                        provider: provider,
                        isConfigured: searchManager.isProviderConfigured(provider),
                        isExpanded: expandedProvider == provider,
                        isDefault: searchManager.activeProvider == provider,
                        apiKey: Binding(
                            get: { apiKeys[provider] ?? "" },
                            set: { apiKeys[provider] = $0 }
                        ),
                        validationState: validationStates[provider] ?? .idle,
                        onToggleExpand: {
                            withAnimation(AetherTheme.Animation.spring) {
                                expandedProvider = expandedProvider == provider ? nil : provider
                            }
                        },
                        onSave: { saveKey(for: provider) },
                        onRemove: { removeKey(for: provider) },
                        onSetDefault: { setDefault(provider) },
                        onValidate: { validateKey(for: provider) }
                    )
                }

                // Connected status
                let configured = searchManager.configuredProviders
                if !configured.isEmpty {
                    HStack(spacing: AetherTheme.Spacing.md) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AetherTheme.Colors.success)
                        Text("\(configured.count) provider\(configured.count == 1 ? "" : "s") connected")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                    }
                    .padding(.top, AetherTheme.Spacing.sm)
                }
            }
            .padding(.horizontal, AetherTheme.Spacing.xxl)
            .padding(.bottom, AetherTheme.Spacing.xxl)
        }
    }

    // MARK: - Actions

    private func saveKey(for provider: SearchProviderType) {
        guard let key = apiKeys[provider], !key.isEmpty else { return }
        validationStates[provider] = .validating

        Task {
            do {
                let valid = try await searchManager.validateAPIKey(key, for: provider)
                await MainActor.run {
                    if valid {
                        try? searchManager.saveAPIKey(key, for: provider)
                        apiKeys[provider] = ""
                        validationStates[provider] = .valid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            if validationStates[provider] == .valid {
                                validationStates[provider] = .idle
                            }
                        }
                    } else {
                        validationStates[provider] = .invalid("Invalid API key")
                    }
                }
            } catch {
                await MainActor.run {
                    validationStates[provider] = .invalid(error.localizedDescription)
                }
            }
        }
    }

    private func removeKey(for provider: SearchProviderType) {
        try? searchManager.removeAPIKey(for: provider)
        validationStates[provider] = .idle
    }

    private func setDefault(_ provider: SearchProviderType) {
        UserDefaults.standard.set(provider.rawValue, forKey: AppConstants.UserDefaultsKeys.defaultSearchProvider)
    }

    private func validateKey(for provider: SearchProviderType) {
        guard let key = apiKeys[provider], !key.isEmpty else { return }
        validationStates[provider] = .validating

        Task {
            do {
                let valid = try await searchManager.validateAPIKey(key, for: provider)
                await MainActor.run {
                    validationStates[provider] = valid ? .valid : .invalid("Invalid key")
                }
            } catch {
                await MainActor.run {
                    validationStates[provider] = .invalid(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Provider Card

private struct ProviderCard: View {
    let provider: SearchProviderType
    let isConfigured: Bool
    let isExpanded: Bool
    let isDefault: Bool
    @Binding var apiKey: String
    let validationState: IntegrationsSettingsView.ValidationState
    let onToggleExpand: () -> Void
    let onSave: () -> Void
    let onRemove: () -> Void
    let onSetDefault: () -> Void
    let onValidate: () -> Void

    @State private var isHovering = false
    @State private var showRemoveConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onToggleExpand) {
                HStack(spacing: AetherTheme.Spacing.lg) {
                    // Provider icon
                    ZStack {
                        RoundedRectangle(cornerRadius: AetherTheme.Radius.lg, style: .continuous)
                            .fill(providerGradient.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: provider.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(providerColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AetherTheme.Spacing.md) {
                            Text(provider.rawValue)
                                .font(AetherTheme.Typography.heading)
                                .foregroundColor(AetherTheme.Colors.textPrimary)

                            if isDefault {
                                Text("DEFAULT")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(AetherTheme.Colors.accent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(AetherTheme.Colors.accentSubtle)
                                    )
                            }
                        }

                        Text(provider.tagline)
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(AetherTheme.Colors.textSecondary)
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: AetherTheme.Spacing.sm) {
                        Circle()
                            .fill(isConfigured ? AetherTheme.Colors.success : AetherTheme.Colors.textTertiary.opacity(0.4))
                            .frame(width: 7, height: 7)

                        Text(isConfigured ? "Connected" : "Not configured")
                            .font(AetherTheme.Typography.caption)
                            .foregroundColor(isConfigured ? AetherTheme.Colors.success : AetherTheme.Colors.textTertiary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AetherTheme.Colors.textTertiary)
                }
                .padding(AetherTheme.Spacing.xl)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .background(AetherTheme.Colors.glassBorderSubtle)
                    .padding(.horizontal, AetherTheme.Spacing.xl)

                VStack(alignment: .leading, spacing: AetherTheme.Spacing.lg) {
                    // Description
                    Text(provider.description)
                        .font(AetherTheme.Typography.caption)
                        .foregroundColor(AetherTheme.Colors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // API key input
                    VStack(alignment: .leading, spacing: AetherTheme.Spacing.md) {
                        Text("API Key")
                            .font(AetherTheme.Typography.captionMedium)
                            .foregroundColor(AetherTheme.Colors.textPrimary)

                        HStack(spacing: AetherTheme.Spacing.md) {
                            SecureField(
                                isConfigured ? "Key configured — enter new to replace" : "Enter your \(provider.rawValue) API key",
                                text: $apiKey
                            )
                            .textFieldStyle(.plain)
                            .font(AetherTheme.Typography.body)
                            .padding(.horizontal, AetherTheme.Spacing.lg)
                            .padding(.vertical, AetherTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                                    .fill(AetherTheme.Colors.surfaceElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                                    .strokeBorder(AetherTheme.Colors.border, lineWidth: 0.5)
                            )

                            if !apiKey.isEmpty {
                                Button(action: onSave) {
                                    Group {
                                        if validationState == .validating {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                        } else {
                                            Text("Save")
                                        }
                                    }
                                    .font(AetherTheme.Typography.captionMedium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AetherTheme.Spacing.lg)
                                    .padding(.vertical, AetherTheme.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: AetherTheme.Radius.md, style: .continuous)
                                            .fill(AetherTheme.Colors.accent)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(validationState == .validating)
                            }
                        }

                        // Validation feedback
                        switch validationState {
                        case .valid:
                            Label("API key saved successfully", systemImage: "checkmark.circle.fill")
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.success)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        case .invalid(let msg):
                            Label(msg, systemImage: "exclamationmark.triangle.fill")
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.error)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        case .validating:
                            Label("Validating...", systemImage: "arrow.triangle.2.circlepath")
                                .font(AetherTheme.Typography.caption)
                                .foregroundColor(AetherTheme.Colors.textSecondary)
                        case .idle:
                            EmptyView()
                        }
                    }

                    // Actions for configured providers
                    if isConfigured {
                        HStack(spacing: AetherTheme.Spacing.lg) {
                            if !isDefault {
                                Button(action: onSetDefault) {
                                    Label("Set as Default", systemImage: "star")
                                        .font(AetherTheme.Typography.caption)
                                        .foregroundColor(AetherTheme.Colors.accent)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Button(action: { showRemoveConfirm = true }) {
                                Label("Remove Key", systemImage: "trash")
                                    .font(AetherTheme.Typography.caption)
                                    .foregroundColor(AetherTheme.Colors.error)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(AetherTheme.Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            ZStack {
                VisualEffectBlur(material: .popover)
                AetherTheme.Colors.glassCard.opacity(0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AetherTheme.Radius.xl, style: .continuous)
                .strokeBorder(
                    isConfigured
                        ? providerColor.opacity(0.2)
                        : AetherTheme.Colors.glassBorderSubtle,
                    lineWidth: 0.5
                )
        )
        .shadow(color: AetherTheme.Colors.shadowSubtle, radius: 8, x: 0, y: 2)
        .onHover { hovering in
            withAnimation(AetherTheme.Animation.fast) { isHovering = hovering }
        }
        .alert("Remove API Key?", isPresented: $showRemoveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { onRemove() }
        } message: {
            Text("This will disconnect \(provider.rawValue) from Aether. You can reconnect anytime by adding a new key.")
        }
        .animation(AetherTheme.Animation.spring, value: validationState)
    }

    private var providerColor: Color {
        switch provider {
        case .serper: return Color.green
        case .firecrawl: return Color.orange
        case .exa: return Color.purple
        case .tavily: return AetherTheme.Colors.accent
        }
    }

    private var providerGradient: LinearGradient {
        LinearGradient(
            colors: [providerColor, providerColor.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
