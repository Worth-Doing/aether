import XCTest
@testable import AetherCore
import Foundation

final class PanelNodeTests: XCTestCase {
    func testAllPanelIds() {
        let a = UUID()
        let b = UUID()
        let c = UUID()

        let layout = PanelNode.split(
            axis: .vertical,
            ratio: 0.6,
            first: .split(axis: .horizontal, ratio: 0.5, first: .leaf(panelId: a), second: .leaf(panelId: b)),
            second: .leaf(panelId: c)
        )

        let ids = layout.allPanelIds
        XCTAssertEqual(ids.count, 3)
        XCTAssertTrue(ids.contains(a))
        XCTAssertTrue(ids.contains(b))
        XCTAssertTrue(ids.contains(c))
    }

    func testReplacingPanel() {
        let a = UUID()
        let b = UUID()
        let newNode = PanelNode.split(
            axis: .horizontal,
            ratio: 0.5,
            first: .leaf(panelId: UUID()),
            second: .leaf(panelId: UUID())
        )

        let layout = PanelNode.split(
            axis: .horizontal,
            ratio: 0.5,
            first: .leaf(panelId: a),
            second: .leaf(panelId: b)
        )

        let updated = layout.replacingPanel(a, with: newNode)
        XCTAssertEqual(updated.allPanelIds.count, 3)
        XCTAssertFalse(updated.allPanelIds.contains(a))
    }

    func testRemovingPanel() {
        let a = UUID()
        let b = UUID()

        let layout = PanelNode.split(
            axis: .horizontal,
            ratio: 0.5,
            first: .leaf(panelId: a),
            second: .leaf(panelId: b)
        )

        let result = layout.removingPanel(a)
        XCTAssertEqual(result, .leaf(panelId: b))
    }

    func testCodableRoundtrip() throws {
        let original = PanelNode.split(
            axis: .vertical,
            ratio: 0.7,
            first: .leaf(panelId: UUID()),
            second: .leaf(panelId: UUID())
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PanelNode.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
