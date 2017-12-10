import Foundation

public enum Tile: CustomStringConvertible {
    case safe, trap

    public init(_ tile: String.UTF8View.Iterator.Element) {
        switch tile {
        case ".".utf8.first!: self = .safe
        case "^".utf8.first!: self = .trap
        default: fatalError()
        }
    }

    public var description: String {
        switch self {
        case .safe: return "."
        case .trap: return "^"
        }
    }

    public static func next(left: Tile, center: Tile, right: Tile) -> Tile {
        switch (left, center, right) {
        case (.trap, .trap, .safe): return .trap
        case (.safe, .trap, .trap): return .trap
        case (.trap, .safe, .safe): return .trap
        case (.safe, .safe, .trap): return .trap
        default: return .safe
        }
    }
}

extension String {
    public init(_ tiles: [Tile]) {
        self = tiles.map { $0.description }.joined()
    }

    public func toTiles() -> [Tile] {
        return self.utf8.map { Tile($0) }
    }
}

public struct Row: CustomStringConvertible {
    let tiles: [Tile]

    init(_ tiles: [Tile]) {
        self.tiles = tiles
    }

    public init(_ tiles: String) {
        self.tiles = tiles.toTiles()
    }

    public func nextRow() -> Row {
        return Row(self.tiles.enumerated().map { (offset: Int, center: Tile) -> Tile in
            let left: Tile

            if offset == tiles.startIndex {
                left = .safe
            } else {
                left = tiles[offset - 1]
            }

            let right: Tile

            if offset + 1 == tiles.endIndex {
                right = .safe
            } else {
                right = tiles[offset + 1]
            }

            return Tile.next(left: left, center: center, right: right)
        })
    }

    public func safeTiles() -> Int {
        return tiles.reduce(0) { $0 + ($1 == .safe ? 1 : 0) }
    }

    public var description: String {
        return tiles.map { $0.description }.joined()
    }

    public func safeTiles(numRows: Int) -> Int {
        var row = self, safeTiles = 0

        for _ in 0..<numRows {
            safeTiles += row.safeTiles()
            row = row.nextRow()
        }
        
        return safeTiles
    }
}
