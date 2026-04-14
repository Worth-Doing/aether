<p align="center">
    <img src="https://raw.githubusercontent.com/Worth-Doing/brand-assets/main/png/variants/04-horizontal.png" alt="WorthDoing.ai" width="600" />
  </p>

<h1 align="center">Aether</h1>

<p align="center">
  <strong>A native cognitive browser for macOS</strong>
</p>

<p align="center">
  Browse, organize, and remember. Aether helps you think better on the web.
</p>

<p align="center">
  <a href="https://github.com/Worth-Doing/aether/releases/latest">
    <img src="https://img.shields.io/badge/Download-DMG-blue?style=for-the-badge&logo=apple" alt="Download DMG" />
  </a>
</p>

---

## What is Aether?

Aether is a next-generation native macOS browser built with **Swift + SwiftUI**. It combines a premium browsing experience with workspace management, semantic memory, and optional AI-powered intelligence via **OpenRouter**.

Three layers working together:

1. **Browser** — Real, high-quality web browsing via WKWebView
2. **Workspace** — Multi-panel tabs, sessions, saved layouts
3. **Intelligence** — Semantic retrieval, page understanding, AI assist (optional)

## Download

| Platform | Link |
|----------|------|
| macOS (Apple Silicon) | [**Download Aether.dmg**](https://github.com/Worth-Doing/aether/releases/latest/download/Aether.dmg) |

> Signed and notarized with Apple Developer ID. No Gatekeeper warnings.

## Features

### Multi-Panel Browsing
Split your browser into multiple panels — side by side, top and bottom, or in complex grid layouts. Perfect for research, comparison, and deep work.

### Workspaces
Save and restore browsing sessions by project or topic. Each workspace preserves your tabs, panel layout, and context.

### Command Palette
Press `Cmd+K` to open a unified command bar that searches across open tabs, history, bookmarks, and commands — all in one place.

### Semantic Memory
With OpenRouter configured, Aether embeds your browsing history and bookmarks for concept-based retrieval. Find pages by meaning, not just keywords.

### AI Assist
Optional AI-powered features:
- Summarize the current page
- Explain complex content
- Extract action items
- Identify key points

All powered by OpenRouter — bring your own API key.

### Keyboard-First

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New tab |
| `Cmd+W` | Close tab |
| `Cmd+Shift+T` | Reopen closed tab |
| `Cmd+L` | Focus address bar |
| `Cmd+K` | Command palette |
| `Cmd+D` | Bookmark page |
| `Cmd+\` | Split panel horizontally |
| `Cmd+Shift+\` | Split panel vertically |
| `Cmd+[` / `Cmd+]` | Back / Forward |
| `Cmd+R` | Reload |

## Tech Stack

- **Swift 5.9+** / SwiftUI
- **WKWebView** for web rendering
- **SQLite** (via C API) for local persistence
- **macOS Keychain** for secure API key storage
- **OpenRouter** for LLM + embedding APIs
- **Swift Package Manager** — no Xcode dependency for building

## Build from Source

```bash
git clone https://github.com/Worth-Doing/aether.git
cd aether
swift build -c release
swift run Aether
```

Requires macOS 14 (Sonoma) or later.

## Architecture

Aether is composed of 14 modular Swift packages:

| Module | Purpose |
|--------|---------|
| `AetherCore` | Models, protocols, shared types |
| `AetherUI` | Design system — colors, typography, components |
| `BrowserEngine` | WKWebView integration, navigation lifecycle |
| `TabManager` | Tab state, creation, switching |
| `PanelSystem` | Multi-panel workspace, splits, layout |
| `HistoryEngine` | Browsing history, session tracking |
| `BookmarkEngine` | Bookmark storage, folders, search |
| `CommandBar` | Unified address/command bar |
| `AIService` | OpenRouter client (LLM + embeddings) |
| `SemanticEngine` | Vector search, cosine similarity |
| `Onboarding` | First-run experience |
| `Settings` | User preferences, model config |
| `SecureStorage` | Keychain wrapper |
| `Persistence` | SQLite layer, migrations |

## AI Setup

AI features are **optional**. Aether works perfectly as a browser without them.

To enable AI:
1. Get an API key from [OpenRouter](https://openrouter.ai)
2. Enter it during onboarding or in Settings
3. AI features (summarize, explain, semantic search) become available

## Privacy

- All data stored locally on your Mac
- API keys secured in macOS Keychain
- AI calls only send page content when you explicitly request it
- No telemetry, no tracking, no cloud sync

## License

MIT

---

<p align="center">
  Built by <a href="https://github.com/Worth-Doing">Worth-Doing</a>
</p>
