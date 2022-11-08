import Foundation

public enum TileState: Hashable {
    case white, black
}

extension TileState: Flippable {
    public mutating func flip() {
        switch self {
        case .white: self = .black
        case .black: self = .white
        }
    }
}

extension TileState: ConwayRule {
    public static func defaultValue() -> TileState {
        return .white
    }

    public func shouldChange(neighbors: [TileState]) -> Bool {
        switch self {
        case .black:
            let blackNeighbors = neighbors.filter({ $0 == .black }).count
            return blackNeighbors == 0 || blackNeighbors > 2
        case .white:
            let blackNeighbors = neighbors.filter({ $0 == .black }).count
            return blackNeighbors == 2
        }
    }

    public func changedValue() -> Self {
        switch self {
        case .black: return .white
        case .white: return .black
        }
    }
}

extension TileState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .white : return "◽️"
        case .black: return "◾️"
        }
    }
}
