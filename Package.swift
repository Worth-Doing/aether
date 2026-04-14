// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Aether",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Aether", targets: ["Aether"])
    ],
    dependencies: [],
    targets: [
        // MARK: - App Entry Point
        .executableTarget(
            name: "Aether",
            dependencies: [
                "AetherCore",
                "AetherUI",
                "BrowserEngine",
                "TabManager",
                "PanelSystem",
                "HistoryEngine",
                "BookmarkEngine",
                "CommandBar",
                "AIService",
                "SemanticEngine",
                "Onboarding",
                "Settings",
                "SecureStorage",
                "Persistence",
            ]
        ),

        // MARK: - Core
        .target(
            name: "AetherCore",
            dependencies: []
        ),

        // MARK: - UI Design System
        .target(
            name: "AetherUI",
            dependencies: ["AetherCore"]
        ),

        // MARK: - Browser Engine
        .target(
            name: "BrowserEngine",
            dependencies: ["AetherCore"]
        ),

        // MARK: - Tab Management
        .target(
            name: "TabManager",
            dependencies: ["AetherCore", "BrowserEngine"]
        ),

        // MARK: - Panel & Workspace System
        .target(
            name: "PanelSystem",
            dependencies: ["AetherCore", "TabManager"]
        ),

        // MARK: - History
        .target(
            name: "HistoryEngine",
            dependencies: ["AetherCore", "Persistence"]
        ),

        // MARK: - Bookmarks
        .target(
            name: "BookmarkEngine",
            dependencies: ["AetherCore", "Persistence"]
        ),

        // MARK: - Command Bar
        .target(
            name: "CommandBar",
            dependencies: [
                "AetherCore",
                "AetherUI",
                "TabManager",
                "HistoryEngine",
                "BookmarkEngine",
                "SemanticEngine",
            ]
        ),

        // MARK: - AI Service (OpenRouter)
        .target(
            name: "AIService",
            dependencies: ["AetherCore", "SecureStorage"]
        ),

        // MARK: - Semantic Engine
        .target(
            name: "SemanticEngine",
            dependencies: ["AetherCore", "AIService", "Persistence"]
        ),

        // MARK: - Onboarding
        .target(
            name: "Onboarding",
            dependencies: ["AetherCore", "AetherUI", "AIService", "SecureStorage"]
        ),

        // MARK: - Settings
        .target(
            name: "Settings",
            dependencies: ["AetherCore", "AetherUI", "AIService", "SecureStorage"]
        ),

        // MARK: - Secure Storage
        .target(
            name: "SecureStorage",
            dependencies: []
        ),

        // MARK: - Persistence (SQLite)
        .target(
            name: "Persistence",
            dependencies: ["AetherCore"],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "AetherCoreTests",
            dependencies: ["AetherCore"]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"]
        ),
    ]
)
