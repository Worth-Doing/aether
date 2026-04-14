import Foundation

public enum SplitAxis: String, Codable, Sendable {
    case horizontal
    case vertical
}

public indirect enum PanelNode: Codable, Sendable {
    case leaf(panelId: UUID)
    case split(axis: SplitAxis, ratio: Double, first: PanelNode, second: PanelNode)

    public var allPanelIds: [UUID] {
        switch self {
        case .leaf(let panelId):
            return [panelId]
        case .split(_, _, let first, let second):
            return first.allPanelIds + second.allPanelIds
        }
    }

    public func replacingPanel(_ oldId: UUID, with newNode: PanelNode) -> PanelNode {
        switch self {
        case .leaf(let panelId):
            return panelId == oldId ? newNode : self
        case .split(let axis, let ratio, let first, let second):
            return .split(
                axis: axis,
                ratio: ratio,
                first: first.replacingPanel(oldId, with: newNode),
                second: second.replacingPanel(oldId, with: newNode)
            )
        }
    }

    public func removingPanel(_ targetId: UUID) -> PanelNode? {
        switch self {
        case .leaf(let panelId):
            return panelId == targetId ? nil : self
        case .split(let axis, let ratio, let first, let second):
            let newFirst = first.removingPanel(targetId)
            let newSecond = second.removingPanel(targetId)
            if let f = newFirst, let s = newSecond {
                return .split(axis: axis, ratio: ratio, first: f, second: s)
            }
            return newFirst ?? newSecond
        }
    }
}

extension PanelNode: Equatable {
    public static func == (lhs: PanelNode, rhs: PanelNode) -> Bool {
        switch (lhs, rhs) {
        case (.leaf(let a), .leaf(let b)):
            return a == b
        case (.split(let axA, let rA, let fA, let sA), .split(let axB, let rB, let fB, let sB)):
            return axA == axB && rA == rB && fA == fB && sA == sB
        default:
            return false
        }
    }
}
