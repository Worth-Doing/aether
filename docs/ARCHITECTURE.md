# Aether — Architecture Document

## 1. Product Summary

Aether is a native macOS cognitive browser built with Swift + SwiftUI. It combines
a premium browsing experience with workspace management, semantic memory, and
optional AI-powered intelligence via OpenRouter.

Three layers:
1. **Browser** — Real, high-quality web browsing via WKWebView
2. **Workspace** — Multi-panel tabs, sessions, saved layouts
3. **Intelligence** — Semantic retrieval, page understanding, AI assist (optional)

## 2. Module Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Aether (App)                       │
│                   Main window, menus                    │
├──────────┬──────────┬──────────┬────────────────────────┤
│ Onboard  │ Settings │ CommandBar│      AetherUI          │
├──────────┴──────────┴──────────┴────────────────────────┤
│                    PanelSystem                          │
│              (splits, layout, focus)                    │
├─────────────────────────────────────────────────────────┤
│                    TabManager                           │
│            (tabs, groups, tab bar)                      │
├─────────────────────────────────────────────────────────┤
│                   BrowserEngine                         │
│         (WKWebView, navigation, page lifecycle)         │
├──────────┬──────────┬───────────┬───────────────────────┤
│ History  │Bookmarks │ Semantic  │     AIService         │
│ Engine   │ Engine   │ Engine    │  (OpenRouter client)   │
├──────────┴──────────┴───────────┴───────────────────────┤
│                    AetherCore                           │
│         (models, protocols, shared types)               │
├──────────┬──────────────────────────────────────────────┤
│Persistence│              SecureStorage                  │
│ (SQLite)  │              (Keychain)                     │
└──────────┴──────────────────────────────────────────────┘
```

## 3. Browser Engine Strategy

### Why WKWebView
- Apple's native web rendering engine for macOS
- Hardware-accelerated, process-isolated rendering
- Full web standards support (WebKit)
- Native integration with macOS security model
- No external dependencies required

### Integration Design
- Each tab owns one `WKWebView` instance
- `BrowserEngine` module wraps WKWebView in a `WebViewCoordinator`
- Navigation delegate handles: load start, load finish, errors, redirects, title changes
- UI delegate handles: new window requests, permission dialogs, file downloads
- Each panel in a workspace holds a reference to a tab's WebView
- JavaScript injection available for reader mode and page content extraction

### Navigation Lifecycle
```
URL input → WebViewCoordinator.load(url) → WKNavigationDelegate
  → didStartProvisionalNavigation → update loading state
  → didCommit → update URL bar, history entry
  → didFinish → update title, trigger embedding if enabled
  → didFail → show error state
```

## 4. Tab & Multi-Panel Workspace Design

### Tab Model
```swift
struct Tab: Identifiable {
    let id: UUID
    var url: URL?
    var title: String
    var favicon: NSImage?
    var isLoading: Bool
    var canGoBack: Bool
    var canGoForward: Bool
    var lastAccessed: Date
    var workspaceId: UUID?
}
```

### Panel Architecture
- A `Panel` contains one active tab and a tab list
- A `PanelLayout` is a recursive tree of splits:
  - `PanelNode.leaf(panelId)` — single panel
  - `PanelNode.split(axis, ratio, first, second)` — horizontal or vertical split
- The root `PanelLayout` lives in the `Workspace`
- Panels can be split, merged, resized, and reordered
- Focus tracking identifies the active panel for keyboard input

### Workspace Model
```swift
struct Workspace: Identifiable {
    let id: UUID
    var name: String
    var panelLayout: PanelNode
    var panels: [Panel]
    var createdAt: Date
    var lastAccessedAt: Date
}
```

### Panel Split Strategy
```
┌─────────────┬─────────────┐
│             │             │
│   Panel A   │   Panel B   │
│             │             │
├─────────────┴─────────────┤
│         Panel C           │
└───────────────────────────┘

PanelNode.split(.vertical, 0.6,
  .split(.horizontal, 0.5, .leaf(A), .leaf(B)),
  .leaf(C)
)
```

## 5. Data Models

### Core Entities

**HistoryEntry**
- id: UUID
- url: String
- title: String
- visitedAt: Date
- sessionId: UUID
- workspaceId: UUID?
- duration: TimeInterval?
- embeddingVector: [Float]? (populated async)

**Bookmark**
- id: UUID
- url: String
- title: String
- folderId: UUID?
- createdAt: Date
- embeddingVector: [Float]?

**BookmarkFolder**
- id: UUID
- name: String
- parentId: UUID?

**WorkspaceSnapshot**
- id: UUID
- workspaceId: UUID
- name: String
- panelLayoutJSON: String
- tabsJSON: String
- savedAt: Date

**EmbeddingRecord**
- id: UUID
- sourceType: enum (history, bookmark, snippet)
- sourceId: UUID
- vector: [Float]
- textContent: String
- createdAt: Date

**AppSettings**
- openRouterConfigured: Bool
- defaultLLMModel: String
- defaultEmbeddingModel: String
- theme: enum
- various UI preferences

## 6. Persistence Strategy

### SQLite via direct C API wrapper
- Lightweight, no heavy ORM
- Custom `Database` class with typed query builders
- Migration system: numbered SQL files applied in order
- WAL mode for concurrent read performance

### Schema Design
```sql
-- Core tables
CREATE TABLE history (
    id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    title TEXT,
    visited_at REAL NOT NULL,
    session_id TEXT,
    workspace_id TEXT,
    duration REAL
);

CREATE TABLE bookmarks (
    id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    title TEXT,
    folder_id TEXT,
    created_at REAL NOT NULL,
    FOREIGN KEY (folder_id) REFERENCES bookmark_folders(id)
);

CREATE TABLE bookmark_folders (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id TEXT,
    FOREIGN KEY (parent_id) REFERENCES bookmark_folders(id)
);

CREATE TABLE workspaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    panel_layout TEXT NOT NULL,
    tabs TEXT NOT NULL,
    created_at REAL NOT NULL,
    last_accessed_at REAL NOT NULL
);

CREATE TABLE embeddings (
    id TEXT PRIMARY KEY,
    source_type TEXT NOT NULL,
    source_id TEXT NOT NULL,
    vector BLOB NOT NULL,
    text_content TEXT,
    created_at REAL NOT NULL
);

CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- Indexes
CREATE INDEX idx_history_url ON history(url);
CREATE INDEX idx_history_visited ON history(visited_at DESC);
CREATE INDEX idx_history_session ON history(session_id);
CREATE INDEX idx_bookmarks_folder ON bookmarks(folder_id);
CREATE INDEX idx_embeddings_source ON embeddings(source_type, source_id);
```

### File Locations
- Database: `~/Library/Application Support/Aether/aether.db`
- Preferences: `UserDefaults` for simple settings
- API keys: macOS Keychain

## 7. History & Bookmark Architecture

### History Engine
- Auto-records every committed navigation (didCommit)
- Groups entries by session (app launch to close = one session)
- Links entries to active workspace
- Provides search: exact URL match, title substring, domain filter
- Provides grouped views: by date, by session, by workspace, by domain
- Triggers async embedding generation for semantic retrieval

### Bookmark Engine
- Folder-based organization
- Quick-add from current page
- Search by title, URL, folder
- Import/export capability (later phases)

## 8. Semantic Retrieval Plan

### Embedding Pipeline
1. User visits a page → `didFinish` fires
2. Page title + URL + extracted summary queued for embedding
3. Background task sends text to OpenRouter embeddings API
4. Response vector stored in `embeddings` table
5. Same flow for bookmarks when created

### Vector Storage & Search
- Vectors stored as BLOB in SQLite (compact binary float array)
- Cosine similarity computed in-process
- For retrieval: embed query text → compute similarity against stored vectors → rank
- Top-K results returned to command bar or AI features
- No external vector DB needed at this scale (thousands of entries, not millions)

### Retrieval Interface
```swift
protocol SemanticSearchable {
    func search(query: String, limit: Int) async throws -> [SemanticResult]
}

struct SemanticResult {
    let sourceType: SourceType
    let sourceId: UUID
    let title: String
    let url: String
    let score: Float
}
```

## 9. OpenRouter Integration Plan

### Service Architecture
```swift
protocol LLMService {
    func complete(prompt: String, model: String?, system: String?) async throws -> String
    func stream(prompt: String, model: String?) -> AsyncThrowingStream<String, Error>
}

protocol EmbeddingService {
    func embed(texts: [String], model: String?) async throws -> [[Float]]
}

class OpenRouterClient: LLMService, EmbeddingService {
    // Single HTTP client
    // Configurable model selection
    // Retry with exponential backoff
    // Timeout handling
    // Cancellation via Swift structured concurrency
}
```

### API Details
- Base URL: `https://openrouter.ai/api/v1`
- LLM endpoint: `/chat/completions`
- Embeddings endpoint: `/embeddings` (if available) or route to embedding-capable model
- Auth: `Authorization: Bearer <api_key>`
- Headers: `HTTP-Referer`, `X-Title` for OpenRouter attribution

### Default Models
- LLM: `anthropic/claude-sonnet-4` (good balance of quality/speed/cost)
- Embeddings: `openai/text-embedding-3-small` (via OpenRouter)

### Error Handling
- Invalid API key → clear error message, prompt re-entry
- Rate limit → exponential backoff with user notification
- Timeout → cancellable, does not block UI
- Network error → graceful degradation, features disabled

## 10. Onboarding & API Key Flow

### Flow
```
App Launch (first time)
  → Welcome screen (logo, tagline, "Start browsing")
  → Feature overview (3 cards: Browse, Organize, Remember)
  → AI setup (optional)
      → Explain OpenRouter
      → API key input field
      → "Test Connection" button
      → Model selection (defaults pre-filled)
      → "Skip for now" option
  → Ready screen → Launch into browser
```

### Key Storage
- API key stored in macOS Keychain via Security framework
- Never stored in UserDefaults, files, or logs
- Loaded into memory only when needed for API calls
- Key validation on entry (test API call)

## 11. Command Bar Design

### Unified Input
The command bar serves multiple roles based on input:
- Starts with `http://` or `https://` → navigate to URL
- Starts with `/` → command mode (e.g., `/split`, `/workspace`, `/settings`)
- Otherwise → unified search across:
  1. Open tabs (title match)
  2. History (title + URL fuzzy match)
  3. Bookmarks (title + URL fuzzy match)
  4. Workspaces (name match)
  5. Semantic results (if AI configured)

### Ranking
1. Exact URL match → highest
2. Open tab title match → very high
3. Recent history match → high
4. Bookmark match → high
5. Semantic similarity → medium
6. Commands → shown when prefix matches

### Keyboard
- `Cmd+L` → focus command bar
- `Cmd+K` → focus command bar in command mode
- Arrow keys → navigate results
- Enter → execute selected result
- Escape → dismiss

## 12. Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+T | New tab |
| Cmd+W | Close tab |
| Cmd+Shift+T | Reopen closed tab |
| Cmd+L | Focus address bar |
| Cmd+K | Command palette |
| Cmd+D | Bookmark page |
| Cmd+\ | Split panel horizontally |
| Cmd+Shift+\ | Split panel vertically |
| Cmd+1-9 | Switch to tab N |
| Cmd+[ | Go back |
| Cmd+] | Go forward |
| Cmd+R | Reload |
| Cmd+Shift+R | Hard reload |
| Ctrl+Tab | Next tab |
| Ctrl+Shift+Tab | Previous tab |
| Cmd+Option+Arrow | Move focus between panels |
| Cmd+Shift+S | Save workspace |
| Cmd+Shift+O | Open workspace |
| Cmd+Shift+I | AI: Summarize page |

## 13. Security Model

- WKWebView runs in separate process (WebKit default)
- API keys in Keychain only
- No telemetry or external data transmission beyond explicit AI calls
- AI calls send only: page title, URL, and user-selected content
- Full page content never sent without explicit user action
- Settings stored locally only
- No cloud sync (v1)

## 14. Assumptions & Constraints

- macOS 14 (Sonoma) minimum deployment target
- Swift 5.9+ / Swift 6 concurrency
- SwiftUI for all UI, AppKit bridging only where SwiftUI lacks capability
- WKWebView via NSViewRepresentable bridge
- No third-party UI frameworks
- SQLite via direct C API (libsqlite3) — no heavy ORMs
- OpenRouter is the sole AI provider
- Single-window app with workspace tabs (v1)
- No extension system (v1)
- No sync across devices (v1)
