# Aether — Native Cognitive Browser for macOS

## Quick Start
```bash
swift build
swift run Aether
```

## Architecture
- Swift + SwiftUI, macOS 14+
- Swift Package Manager (Package.swift at root)
- WKWebView for web rendering
- OpenRouter for LLM + embeddings
- SQLite (via swift-sqlite) for local persistence
- Keychain for secure API key storage

## Module Structure
- `Sources/Aether/` — App entry point and main window
- `Sources/AetherCore/` — Core models, protocols, shared types
- `Sources/BrowserEngine/` — WKWebView integration, navigation, page lifecycle
- `Sources/TabManager/` — Tab state, tab groups, tab bar UI
- `Sources/PanelSystem/` — Multi-panel workspace, splits, layout persistence
- `Sources/HistoryEngine/` — Browsing history, session tracking
- `Sources/BookmarkEngine/` — Bookmark storage, folders, search
- `Sources/CommandBar/` — Unified address/command bar, fuzzy search
- `Sources/AIService/` — OpenRouter client, LLM + embedding abstractions
- `Sources/SemanticEngine/` — Embedding pipeline, vector storage, semantic retrieval
- `Sources/Onboarding/` — First-run experience, API key setup
- `Sources/Settings/` — User preferences, model config
- `Sources/SecureStorage/` — Keychain wrapper for API keys
- `Sources/Persistence/` — SQLite layer, migrations, repositories
- `Sources/AetherUI/` — Shared design system (colors, typography, components)

## Conventions
- Dark mode first
- Keyboard-first workflows
- AI features are always optional — browser must work without them
- All AI calls are async and cancellable
- No Electron patterns — this is a native Mac app
