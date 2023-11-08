import Foundation
import RegexBuilder

public enum Tile: Character {
    case offmap = " "
    case open = "."
    case wall = "#"

    var onMap: Bool {
        switch self {
        case .offmap:
            return false
        case .open, .wall:
            return true
        }
    }
}

public struct RowOrColumn {
    /// Contiguous range of open tiles / walls, would wrap if there's no wall on edges
    fileprivate let mapRange: Range<Int>
    /// each contiguous range of open tiles. Separated by walls
    fileprivate let openTileRanges: RangeSet<Int>
    /// track whether or not there's a wall that blocks wrapping around
    let wrapsAround: Bool

    public init<C: BidirectionalCollection>(_ tiles: C)
    where C.Index == Int, C.Element == Tile {
        guard let firstMapTile = tiles.firstIndex(where: \.onMap),
              let lastMapTile = tiles.lastIndex(where: \.onMap) else {
            fatalError("row or column with zero map tiles?")
        }

        let upperBound = tiles.index(after: lastMapTile)
        mapRange = (firstMapTile ..< upperBound)

        openTileRanges = tiles.subranges(of: Tile.open)
        wrapsAround = (openTileRanges.contains(firstMapTile)
                       && openTileRanges.contains(lastMapTile))
    }

    /// count might be positive or negative
    public func moving(from start: Int, count: Int) -> Int {
        guard let currentRange = openTileRanges.ranges.first(where: {
            $0.contains(start)
        }) else {
            fatalError("\(start) is off the map or in a wall")
        }

        let destination = start + count

        // fits inside the current bounded area
        if currentRange.contains(destination) {
            return destination
        }

        if currentRange == mapRange {
            // No walls and it wraps around. Figure out where it ends up
            // allowing it to wrap multiple times
            let destRelativeToLowerBound = mod(destination - mapRange.lowerBound, mapRange.count)
            return mapRange.lowerBound + destRelativeToLowerBound
        }

        // doesn't fit into current range, and there's one or more walls
        // along the path
        if count < 0 {
            if currentRange.lowerBound == mapRange.lowerBound && wrapsAround {
                // handle wrap around to upper range
                let stepsRemaining = currentRange.lowerBound - destination
                let upperRange = openTileRanges.ranges.last!
                return max(upperRange.upperBound - stepsRemaining, upperRange.lowerBound)
            } else {
                // not edge of map, hits wall in currentRange
                return currentRange.lowerBound
            }
        } else {
            if currentRange.upperBound == mapRange.upperBound && wrapsAround {
                // handle wrap around to lower range
                let stepsRemaining = destination - currentRange.upperBound
                let lowerRange = openTileRanges.ranges.first!
                return min(lowerRange.lowerBound + stepsRemaining, lowerRange.upperBound - 1)
            } else {
                // not edge of map, hits wall in currentRange
                return currentRange.upperBound - 1
            }
        }
    }

    func tile(at index: Int) -> Tile {
        guard mapRange.contains(index) else { return .offmap }

        if openTileRanges.contains(index) {
            return .open
        } else {
            return .wall
        }
    }
}

public struct Position {
    enum Facing {
        case right, down, left, up
    }

    var row: Int
    var column: Int
    var facing: Facing
}

public enum Instruction {
    public enum Direction {
        case left, right
    }

    case move(Int)
    case turn(Direction)
}

public struct Map {
    // storing both row/column based to make movement easier
    let rows: [RowOrColumn]
    let columns: [RowOrColumn]
    let instructions: [Instruction]

    public init(_ string: String) {
        let lines = string.lines()
        let tiles = lines.dropLast(2)

        var numColumns = 0
        let rows = tiles.map { line in
            numColumns = max(numColumns, line.count)
            return RowOrColumn(line.map({ Tile(rawValue: $0)! }))
        }

        columns = (0 ..< numColumns).map { col in
            let tiles = rows.map { $0.tile(at: col) }
            return RowOrColumn(tiles)
        }
        self.rows = rows

        instructions = Instruction.list(lines.last!)
    }

    public func part1() -> Int {
        let initialColumn = rows[0].openTileRanges.ranges.first!.lowerBound

        var position = Position(row: 0,
                                column: initialColumn,
                                facing: .right)

        for instruction in instructions {
            switch instruction {
            case .move(var distance):
                switch position.facing {
                case .left:
                    distance *= -1
                    fallthrough
                case .right:
                    position.column = rows[position.row]
                        .moving(from: position.column, count: distance)

                case .up:
                    distance *= -1
                    fallthrough
                case .down:
                    position.row = columns[position.column]
                        .moving(from: position.row, count: distance)
                }
            case .turn(let direction):
                position.turn(direction)
            }
        }

        print(position)

        return position.password()
    }
}

extension Position.Facing {
    func passwordValue() -> Int {
        switch self {
        case .right:
            return 0
        case .down:
            return 1
        case .left:
            return 2
        case .up:
            return 3
        }
    }
}

extension Position {
    func password() -> Int {
        // row and column are 1-based
        return (row + 1) * 1000 + (column + 1) * 4 + facing.passwordValue()
    }

    mutating func turn(_ direction: Instruction.Direction) {
        switch (facing, direction) {
        case (.right, .right),
            (.left, .left):
            self.facing = .down
        case (.down, .right),
            (.up, .left):
            self.facing = .left
        case (.left, .right),
            (.right, .left):
            self.facing = .up
        case (.up, .right),
            (.down, .left):
            self.facing = .right
        }
    }
}

/// https://stackoverflow.com/a/41180619
fileprivate func mod(_ a: Int, _ n: Int) -> Int {
    precondition(n > 0, "modulus must be positive")
    let r = a % n
    return r >= 0 ? r : r + n
}

fileprivate func ==(lhs: RangeSet<Int>, rhs: Range<Int>) -> Bool {
    return lhs.ranges.count == 1 && lhs.ranges[0] == rhs
}

let EnglishLocale = Locale(identifier: "en-US")
extension Instruction {
    public static let MatchingRegex = Regex {
        Anchor.startOfLine
        ChoiceOf {
            Capture(.localizedInteger(locale: EnglishLocale))
            Capture({
                ChoiceOf {
                    "L"
                    "R"
                }
            }, transform: Direction.init)
        }
    }

    public static func list(_ string: String) -> [Instruction] {
        var result: [Instruction] = []
        var remaining = string[(string.startIndex ..< string.endIndex)]

        while let nextMatch = try? Instruction.MatchingRegex.prefixMatch(in: remaining) {

            // I can't believe this `keyPath` is the right way to use Regex
            // with varying captures. However, I do like the
            // regex behavior of "consume all digits of number"

            if let distance = nextMatch[keyPath: \.1] {
                result.append(.move(distance))
            } else if let direction = nextMatch[keyPath: \.2] {
                result.append(.turn(direction))
            } else {
                fatalError("Bad match from regex?")
            }

            guard nextMatch.range.upperBound < remaining.endIndex else {
                // done with this string
                break
            }

            remaining = remaining[nextMatch.range.upperBound ..< remaining.endIndex]
        }

        return result
    }
}

extension Instruction.Direction {
    init(_ string: Substring) {
        if string == "L" { self = .left }
        else if string == "R" { self = .right }
        else { fatalError("invalid direction \(string)") }
    }
}

extension Map: CustomStringConvertible {
    public var description: String {
        let map: String = rows.map(\.description).joined(separator: "\n")
        let instruction: String = instructions.map(\.description).joined(separator: "")
        return map + "\n\n\n" + instruction
    }
}

extension RowOrColumn: CustomStringConvertible {
    public var description: String {
        (0 ..< mapRange.upperBound).map { idx in
            String(tile(at: idx).rawValue)
        }.joined()
    }
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .move(let int):
            return String(describing: int)
        case .turn(.left): return "L"
        case .turn(.right): return "R"
        }
    }
}
