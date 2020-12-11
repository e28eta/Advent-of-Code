import Foundation

public struct Grid<E>: RandomAccessCollection, MutableCollection {
    public typealias Element = E
    public typealias Index = GridIndex

    var contents: [[E]]
    let width: Int
    let height: Int

    public struct GridIndex: Strideable {
        let width: Int
        let row: Int
        let col: Int
        let index: Int

        init?(width: Int, row: Int, col: Int) {
            guard row >= 0, col >= 0, col < width else { return nil }
            self.width = width
            self.row = row
            self.col = col
            index = width * row + col
        }

        init(width: Int, index: Int) {
            self.width = width
            self.index = index
            row = index / width
            col = index % width
        }

        public func advanced(by n: Int) -> Grid<E>.GridIndex {
            return GridIndex(width: width,
                             index: index + n)
        }

        public func distance(to other: Grid<E>.GridIndex) -> Int {
            // broken if they have different widths. nbd for me
            return other.index - index
        }
    }

    public var startIndex: GridIndex {
        GridIndex(width: width, index: 0)
    }
    public var endIndex: GridIndex {
        GridIndex(width: width, row: height, col: 0)!
    }

    public init(_ contents: [[E]])  {
        guard contents.count > 0,
              let firstRow = contents.first,
              firstRow.count > 0 else {
            fatalError("Must be non-empty grid")
        }
        guard contents.allSatisfy({ $0.count == firstRow.count }) else {
            fatalError("Every row must be same size")
        }

        self.height = contents.count
        self.width = firstRow.count
        self.contents = contents
    }

    public subscript(position: Index) -> E {
        get {
            contents[position.row][position.col]
        }
        set(newValue) {
            contents[position.row][position.col] = newValue
        }
    }

    public func neighbors(position: Index) -> [Index] {
        return [
            GridIndex(width: width, row: position.row - 1, col: position.col - 1),
            GridIndex(width: width, row: position.row - 1, col: position.col),
            GridIndex(width: width, row: position.row - 1, col: position.col + 1),
            GridIndex(width: width, row: position.row, col: position.col - 1),
            GridIndex(width: width, row: position.row, col: position.col + 1),
            GridIndex(width: width, row: position.row + 1, col: position.col - 1),
            GridIndex(width: width, row: position.row + 1, col: position.col),
            GridIndex(width: width, row: position.row + 1, col: position.col + 1),
        ]
        .compactMap({ $0 }) // eliminate indices off the grid above, left or right
        .filter({ $0.row < height }) // eliminate indices off the grid below
    }

    public func neighborCount(position: Index, isIncluded predicate: (GridIndex) -> Bool) -> Int {
        return neighbors(position: position).filter(predicate).count
    }
}

extension Grid: CustomStringConvertible where Grid.Element: CustomStringConvertible {
    public var description: String {
        return contents.map { r in
            r.map(\.description).joined()
        }.joined(separator: "\n")
    }
}

extension Grid where Grid.Element: Equatable {
    public func neighborCount(position: Index, expected: Element) -> Int {
        return neighbors(position: position).filter { self[$0] == expected}.count
    }
}
