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
- Adaptive light/dark theme system (default: light)

## Module Structure
- `Sources/Aether/` — App entry point, main window, all views
- `Sources/AetherCore/` — Core models, protocols, shared types, constants
- `Sources/BrowserEngine/` — WKWebView integration, navigation, page lifecycle, find-in-page, zoom
- `Sources/TabManager/` — Tab state, tab groups, tab bar UI
- `Sources/PanelSystem/` — Multi-panel workspace, splits, layout persistence
- `Sources/HistoryEngine/` — Browsing history, session tracking
- `Sources/BookmarkEngine/` — Bookmark storage, folders, search
- `Sources/CommandBar/` — Unified command palette with 10+ commands, fuzzy search
- `Sources/AIService/` — OpenRouter client, LLM + embedding abstractions
- `Sources/SemanticEngine/` — Embedding pipeline, vector storage, semantic retrieval
- `Sources/Onboarding/` — First-run experience, API key setup
- `Sources/Settings/` — Tabbed settings (General, Appearance, AI, Privacy, About)
- `Sources/SecureStorage/` — Keychain wrapper for API keys
- `Sources/Persistence/` — SQLite layer, migrations, repositories
- `Sources/AetherUI/` — Design system (adaptive colors, typography, components)

## Key Features
- Adaptive light/dark theme with system-follow option
- Multi-panel workspaces with split views
- Find in page (Cmd+F)
- Zoom controls (Cmd+/-, Cmd+0)
- Tab pinning and context menus
- AI assist with actions mode + chat mode
- Command palette with 10+ commands
- Status bar with connection info and zoom level
- Configurable search engine (DuckDuckGo, Google, Bing, Brave)
- Semantic search via embeddings (auto-indexed)
- Bookmark folders with disclosure groups
- History grouped by date (Today, Yesterday, This Week, Earlier)

## Conventions
- Light mode default, dark mode supported
- Keyboard-first workflows
- AI features are always optional — browser must work without them
- All AI calls are async and cancellable
- No Electron patterns — this is a native Mac app
- Adaptive colors use NSColor dynamic provider for automatic light/dark
- Settings use @AppStorage with keys from AppConstants.UserDefaultsKeys
