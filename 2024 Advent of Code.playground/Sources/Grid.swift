import Foundation

public struct GridIndex: Strideable, CustomDebugStringConvertible {
    public let width: Int
    public let row: Int
    public let col: Int
    let index: Int

    init?(width: Int, row: Int, col: Int) {
        guard row >= 0, col >= 0, col < width else { return nil }
        self.width = width
        self.row = row
        self.col = col
        self.index = width * row + col
    }

    init(width: Int, index: Int) {
        self.width = width
        self.index = index
        self.row = index / width
        self.col = index % width
    }

    public func advanced(by n: Int) -> Self {
        return GridIndex(width: width,
                         index: index + n)
    }

    public func advanced(by rc: (Int, Int), limitedTo endIndex: GridIndex) -> Self? {
        guard let result = GridIndex(width: width,
                                     row: row + rc.0,
                                     col: col + rc.1),
              result.distance(to: endIndex) > 0 else { return nil }
        return result

    }

    public func distance(to other: Self) -> Int {
        // broken if they have different widths. nbd for me
        return other.index - index
    }

    /// Number of up/down and left/right steps between these two locations on the grid
    public func manhattanDistance(to other: Self) -> Int {
        return abs(row - other.row) + abs(col - other.col)
    }

    public var debugDescription: String {
        return "(\(row), \(col))"
    }
}

extension GridIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(col)
    }
}

public protocol NeighborConnectivity {
    func possibleNeighbors() -> any Sequence<(Int, Int)>
}

public enum GridConnectivity: NeighborConnectivity {
    case fourWay, eightWay

    public func possibleNeighbors() -> any Sequence<(Int, Int)> {
        switch self {
        case .fourWay:
            return [
                (-1, 0),
                (0, -1),
                (0, 1),
                (1, 0),
            ]
        case .eightWay:
            return [
                (-1, -1),
                (-1, 0),
                (-1, 1),
                (0, -1),
                (0, 1),
                (1, -1),
                (1, 0),
                (1, 1)
            ]
        }
    }
}

public struct Grid<E>: RandomAccessCollection, MutableCollection {
    public typealias Element = E
    public typealias Index = GridIndex

    var contents: [[E]]
    public let width: Int
    public let height: Int
    let connectivity: NeighborConnectivity
    let neighbors: [[Index]]

    public let startIndex: Index
    public let endIndex: Index

    public init(_ contents: [[E]], connectivity: NeighborConnectivity)  {
        guard contents.count > 0,
              let width = contents.first?.count,
              width > 0 else {
            fatalError("Must be non-empty grid")
        }
        guard contents.allSatisfy({ $0.count == width }) else {
            fatalError("Every row must be same size")
        }

        self.height = contents.count
        self.width = width
        self.contents = contents

        let startIndex = GridIndex(width: width, index: 0)
        let endIndex = GridIndex(width: width, index: height * width)
        self.startIndex = startIndex
        self.endIndex = endIndex

        self.connectivity = connectivity
        neighbors = (startIndex..<endIndex).map { position in
            return connectivity.possibleNeighbors().compactMap {
                position.advanced(by: $0, limitedTo: endIndex)
            }
        }
    }

    public subscript(position: Index) -> E {
        get {
            contents[position.row][position.col]
        }
        set(newValue) {
            contents[position.row][position.col] = newValue
        }
    }

    public subscript(_ row: Int, _ col: Int) -> E? {
        get {
            guard (0 ..< height).contains(row) && (0 ..< width).contains(col) else {
                return nil
            }
            return GridIndex(width: width, row: row, col: col)
                .map { idx in self[idx] }
        }
    }

    public func neighbors(of position: Index) -> [GridIndex] {
        return neighbors[position.index]
    }

    public func neighbors(row: Int, col: Int) -> [GridIndex] {
        guard let position = GridIndex(width: width, row: row, col: col) else {
            return []
        }
        return neighbors(of: position)
    }

    public func neighborCount(position: Index, isIncluded predicate: (Index) -> Bool) -> Int {
        return neighbors[position.index].filter(predicate).count
    }
}

extension Grid: CustomStringConvertible where Grid.Element: CustomStringConvertible {
    public var description: String {
        return contents.map { row in
            row.map(\.description).joined()
        }.joined(separator: "\n")
    }
}

extension Grid where Grid.Element: Equatable {
    public func neighborCount(position: Index, expected: Element) -> Int {
        return neighbors[position.index].filter { self[$0] == expected }.count
    }
}

extension Grid {
    public func transformElements<T>(_ transform: (Grid.Element) throws -> T) rethrows -> Grid<T> {

        return Grid<T>(
            try contents.map({ try $0.map(transform) }),
            connectivity: connectivity)
    }
}
