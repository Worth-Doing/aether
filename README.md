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

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/version-0.3.0-green" alt="v0.3.0" />
  <img src="https://img.shields.io/badge/notarized-Apple-black" alt="Notarized" />
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

## What's New in v0.3.0

### Glass UI Redesign (iOS 26 Aesthetic)
- **Glassmorphism throughout** — Frosted blur, translucent panels, depth hierarchy
- **NSVisualEffectView integration** — Real macOS vibrancy materials on toolbar, sidebar, command bar, AI panel
- **Glass design tokens** — 15 new adaptive glass colors (`glassBackground`, `glassSurface`, `glassCard`, `glassBorder`, etc.)
- **Gradient borders** — Top-to-bottom gradient stroke on floating elements
- **Glow effects** — Accent-colored blur circles behind icons on empty states
- **Press animations** — Scale-down spring animation on all interactive glass components
- **Spring-dominant motion** — Replaced ease-in-out with physics-based spring curves

### New Components
- **GlassIconButton** — Icon button with glass hover state, press scale, and accessibility label
- **GlassCard** — Hover-responsive frosted card with gradient border
- **GlassCommandCard** — Floating command bar with deep shadow and blur
- **VisualEffectBlur** — NSVisualEffectView wrapper for SwiftUI
- **View modifiers** — `.glassBackground()`, `.glassCard()`, `.glassPanel()`, `.glassToolbar()`

### Toast Notification System
- **ToastManager** — Observable toast system with auto-dismiss (2.5s)
- **Glass toast capsule** — Frosted pill with icon, message, and color-coded glow
- **Bookmark feedback** — "Bookmark added" / "Bookmark removed" toasts

### Security Fixes
- **Fixed 3 SQL injection vulnerabilities** — DELETE operations now use parameterized queries
- **KVO memory leak fix** — WebViewCoordinator now invalidates all 6 observations in `deinit`
- **Proper error handling** — Replaced 19 silent `try?` catches with `lastError` state propagation

### Feature Upgrades
- **Workspace persistence** — Workspaces now saved to SQLite (schema was unused before)
- **Session save on quit** — App saves workspace state on exit
- **WorkspaceRepository** — Full CRUD for workspace persistence

### Performance
- **Accelerate-optimized vector search** — Cosine similarity uses `vDSP_dotpr` instead of manual loops
- **Optimized URLSession** — Connection pooling with `httpMaximumConnectionsPerHost`

### Previous (v0.2.0)
- Light mode default, find in page, zoom controls, tab pinning, AI chat mode, 11 command palette commands, configurable search engine, tabbed settings, semantic auto-indexing

## Features

### Multi-Panel Browsing
Split your browser into multiple panels — side by side, top and bottom, or in complex grid layouts. Perfect for research, comparison, and deep work.

### Workspaces
Save and restore browsing sessions by project or topic. Each workspace preserves your tabs, panel layout, and context.

### Command Palette
Press `Cmd+K` to open a unified command bar that searches across open tabs, history, bookmarks, and commands — all in one place. 11 built-in commands with keyboard shortcut hints.

### Adaptive Theme
Light mode by default with full dark mode support. Choose Light, Dark, or System in Settings > Appearance.

### Find in Page
Press `Cmd+F` to search within the current page. Navigate matches with forward/backward buttons.

### Semantic Memory
With OpenRouter configured, Aether embeds your browsing history and bookmarks for concept-based retrieval. Find pages by meaning, not just keywords. History is automatically indexed on every navigation.

### AI Assist
Optional AI-powered features:
- **Summarize** — Get a concise summary of any page
- **Explain** — Break down complex content in simple terms
- **Key Points** — Extract the most important facts
- **Extract Actions** — Pull out action items and to-dos
- **Simplify** — Rewrite content in simpler language
- **Translate** — Translate page content to English
- **Chat Mode** — Ask questions about the current page in a multi-turn conversation

All powered by OpenRouter — bring your own API key.

### Tab Management
- Pin important tabs (compact icon display)
- Right-click context menus (duplicate, reload, copy URL, close others)
- Reopen recently closed tabs (`Cmd+Shift+T`)
- Tab count displayed in status bar

### Configurable Search Engine
Choose your default in Settings > General:
- DuckDuckGo (default)
- Google
- Bing
- Brave

### Keyboard-First

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | New tab |
| `Cmd+W` | Close tab |
| `Cmd+Shift+T` | Reopen closed tab |
| `Cmd+L` | Focus address bar |
| `Cmd+K` | Command palette |
| `Cmd+D` | Bookmark page |
| `Cmd+F` | Find in page |
| `Cmd+\` | Split panel horizontally |
| `Cmd+Shift+\` | Split panel vertically |
| `Cmd+Shift+S` | Toggle sidebar |
| `Cmd++` | Zoom in |
| `Cmd+-` | Zoom out |
| `Cmd+0` | Reset zoom |
| `Cmd+[` / `Cmd+]` | Back / Forward |
| `Cmd+R` | Reload |
| `Cmd+,` | Settings |
| `Cmd+Shift+N` | New workspace |

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
swift build
swift run Aether
```

Requires macOS 14 (Sonoma) or later and Xcode 15+.

## Architecture

Aether is composed of 15 modular Swift packages:

| Module | Purpose |
|--------|---------|
| `Aether` | App entry point, all views |
| `AetherCore` | Models, protocols, constants |
| `AetherUI` | Design system — adaptive colors, typography, components |
| `BrowserEngine` | WKWebView, navigation, find-in-page, zoom |
| `TabManager` | Tab state, pinning, recently closed |
| `PanelSystem` | Multi-panel workspace, splits, layout |
| `HistoryEngine` | Browsing history, session tracking |
| `BookmarkEngine` | Bookmark storage, folders, search |
| `CommandBar` | Unified command palette (11 commands) |
| `AIService` | OpenRouter client (LLM + embeddings) |
| `SemanticEngine` | Vector search, cosine similarity |
| `Onboarding` | First-run experience |
| `Settings` | Tabbed preferences (General, Appearance, AI, Privacy, About) |
| `SecureStorage` | Keychain wrapper |
| `Persistence` | SQLite layer, migrations |

## AI Setup

AI features are **optional**. Aether works perfectly as a browser without them.

To enable AI:
1. Get an API key from [OpenRouter](https://openrouter.ai)
2. Enter it during onboarding or in Settings > AI
3. AI features (summarize, explain, chat, semantic search) become available

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
