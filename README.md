<p align="center">
    <img src="https://raw.githubusercontent.com/Worth-Doing/brand-assets/main/png/variants/04-horizontal.png" alt="WorthDoing.ai" width="600" />
  </p>

<h1 align="center">Aether</h1>

<p align="center">
  <strong>A next-generation cognitive browser for macOS</strong>
</p>

<p align="center">
  Browse, search, organize, and understand the web — powered by AI.
</p>

<p align="center">
  <a href="https://github.com/Worth-Doing/aether/releases/latest">
    <img src="https://img.shields.io/badge/Download-DMG-blue?style=for-the-badge&logo=apple" alt="Download DMG" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/version-1.0.0-green" alt="v1.0.0" />
  <img src="https://img.shields.io/badge/notarized-Apple-black" alt="Notarized" />
</p>

---

## What is Aether?

Aether is a native macOS browser built with **Swift + SwiftUI** that combines premium browsing with AI-powered web intelligence, multi-panel workspaces, and deep search integrations.

Four layers working together:

1. **Browser** — Fast, native web browsing via WKWebView
2. **Workspace** — Multi-panel tabs, sessions, saved layouts
3. **Intelligence** — AI page analysis, semantic memory, reading mode
4. **Search** — Firecrawl, Exa, Tavily, and Serper integrations for web/images/videos/news

## Download

| Platform | Link |
|----------|------|
| macOS (Apple Silicon) | [**Download Aether.dmg**](https://github.com/Worth-Doing/aether/releases/latest/download/Aether.dmg) |

> Signed and notarized with Apple Developer ID. No Gatekeeper warnings.

---

## What's New in v1.0.0

### AI-Powered Search with 4 Providers
Connect your own API keys for powerful web intelligence:

| Provider | Capabilities |
|----------|-------------|
| **Serper** | Google Search API — Web, Images, Videos, News with dedicated endpoints |
| **Firecrawl** | Web scraping & content extraction, returns LLM-ready markdown |
| **Exa** | Neural search with highlights, summaries, and deep search modes |
| **Tavily** | Research-grade search with AI-generated answers |

- **7 search modes**: Web, Images, Videos, News, Research, Fast, Deep
- **Rich media results**: Image grid with thumbnails, video cards with duration/channel, news cards with source/date
- **Knowledge Graph**: Google knowledge panels displayed inline
- **AI Answers**: LLM-generated answers from Tavily and Exa
- **Split-view preview**: Select a result to see full content in a side panel
- **Search caching**: 5-minute TTL cache prevents redundant API calls
- **Auto provider routing**: Images/Videos/News modes auto-select Serper when available

### Reading Mode
- Distraction-free reader with **serif typography**
- Adjustable **font size** (13–24pt), **column width** (500–900px), **line spacing**
- Floating glass control panel
- One-click activation from status bar

### AI Assist with Markdown Rendering
- **6 page actions**: Summarize, Explain, Key Points, Extract Actions, Simplify, Translate
- **Chat mode**: Multi-turn conversation about the current page with auto-scroll
- **Markdown output**: Bold, italic, bullets, code blocks rendered natively
- System prompts instruct the LLM to format responses with markdown

### Quick Notes & Page Intelligence
- **Notes tab**: Scratchpad with character count and copy-to-clipboard
- **Summary tab**: One-click AI page summarization
- **Key Points tab**: Numbered key point extraction

### Download Manager
- Progress tracking with animated bar
- File type icons (PDF, ZIP, DMG, images, video, audio, code)
- Active/Completed sections
- Open in Finder, remove, clear completed
- Active download indicator dot on status bar

### Enhanced New Tab Page
- Live clock display
- Search bar with glass morphism
- **Recent sites grid**: Top 8 unique domains from history
- **Bookmarks grid**: Quick access to saved bookmarks
- Quick action cards: AI Search, Settings

### Premium Integrations Settings
- Beautiful provider cards with expand/collapse
- Status badges (Connected / Not configured)
- Secure API key input with validation
- Set default provider
- Provider descriptions and capabilities

### Visual Overhaul
- **Toolbar**: Navigation button cluster, gradient background, premium address bar
- **Tab bar**: Refined close button with red hover state, active tab shadow
- **Sidebar**: Inline search/filter for bookmarks and history
- **Status bar**: Reading Mode, Quick Notes, Downloads buttons with tooltips

### Previous Versions
- **v0.3.0**: Glass UI redesign, security fixes, workspace persistence
- **v0.2.0**: Light theme, find in page, zoom, tab pinning, AI chat, command palette

---

## Features

### Multi-Panel Browsing
Split your browser into multiple panels — side by side, top and bottom, or complex layouts. Draggable dividers between panels.

### Workspaces
Save and restore browsing sessions by project. Each workspace preserves tabs, panel layout, and context.

### Command Palette
Press `Cmd+K` to search across open tabs, history, bookmarks, and commands. 11 built-in commands with keyboard shortcut hints.

### AI Assist
Optional AI-powered page analysis:
- **Summarize** — Concise page summary with markdown formatting
- **Explain** — Break down complex content
- **Key Points** — Extract important facts as a bullet list
- **Extract Actions** — Pull out action items as a checklist
- **Simplify** — Rewrite in simpler language
- **Translate** — Translate to English
- **Chat Mode** — Multi-turn conversation about the current page

All powered by [OpenRouter](https://openrouter.ai) — bring your own API key.

### Search Integrations
Connect one or more search APIs in Settings > Integrations:
- **Serper** — Google Search with web, images, videos, news
- **Firecrawl** — Web scraping and content extraction
- **Exa** — Neural/semantic web search
- **Tavily** — Research search with AI answers

### Tab Management
- Pin tabs, duplicate, reload, copy URL
- Reopen recently closed tabs (`Cmd+Shift+T`)
- Close other tabs from context menu

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
| `Cmd+\` | Split horizontally |
| `Cmd+Shift+\` | Split vertically |
| `Cmd+Shift+S` | Toggle sidebar |
| `Cmd++` / `Cmd+-` / `Cmd+0` | Zoom in / out / reset |
| `Cmd+[` / `Cmd+]` | Back / Forward |
| `Cmd+R` | Reload |
| `Cmd+,` | Settings |
| `Cmd+Shift+N` | New workspace |

---

## Tech Stack

- **Swift 5.9+** / SwiftUI
- **WKWebView** for web rendering
- **SQLite** (via C API) for local persistence
- **macOS Keychain** for secure API key storage
- **OpenRouter** for LLM + embedding APIs
- **Serper / Firecrawl / Exa / Tavily** for web search
- **Swift Package Manager** — no Xcode dependency

## Build from Source

```bash
git clone https://github.com/Worth-Doing/aether.git
cd aether
swift build
swift run Aether
```

Requires macOS 14 (Sonoma) or later and Xcode 15+.

## Architecture

Aether is composed of 16 modular Swift packages:

| Module | Purpose |
|--------|---------|
| `Aether` | App entry point, all views |
| `AetherCore` | Models, protocols, constants |
| `AetherUI` | Design system — colors, typography, glass components |
| `BrowserEngine` | WKWebView, navigation, content extraction, find-in-page, zoom |
| `TabManager` | Tab state, pinning, recently closed |
| `PanelSystem` | Multi-panel workspace, splits, layout |
| `HistoryEngine` | Browsing history, session tracking |
| `BookmarkEngine` | Bookmark storage, folders, search |
| `CommandBar` | Unified command palette (11 commands) |
| `AIService` | OpenRouter client (LLM + embeddings) |
| `SemanticEngine` | Vector search, cosine similarity via Accelerate |
| `WebSearchService` | Serper, Firecrawl, Exa, Tavily adapters + SearchManager |
| `Onboarding` | First-run experience |
| `Settings` | Tabbed preferences with integrations management |
| `SecureStorage` | Keychain wrapper |
| `Persistence` | SQLite layer, migrations |

## AI & Search Setup

AI features and search integrations are **optional**. Aether works perfectly as a browser without them.

### OpenRouter (AI Assist)
1. Get an API key from [OpenRouter](https://openrouter.ai)
2. Enter it during onboarding or in Settings > AI
3. AI features (summarize, explain, chat, reading mode intelligence) become available

### Search Providers
1. Go to Settings > Integrations
2. Expand a provider card (Serper, Firecrawl, Exa, or Tavily)
3. Enter your API key — it will be validated and stored securely in Keychain
4. Use the search icon in the toolbar or `Cmd+K` to search

## Privacy

- All data stored locally on your Mac
- API keys secured in macOS Keychain
- AI calls only send page content when you explicitly request it
- Search queries only sent to providers you configure
- No telemetry, no tracking, no cloud sync

## License

MIT

---

<p align="center">
  Built by <a href="https://github.com/Worth-Doing">Worth-Doing</a>
</p>
