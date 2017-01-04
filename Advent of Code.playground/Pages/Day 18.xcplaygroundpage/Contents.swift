//: [Previous](@previous)

/*:
 # Day 18: Like a Rogue

 As you enter this room, you hear a loud click! Some of the tiles in the floor here seem to be pressure plates for [traps](https://nethackwiki.com/wiki/Trap), and the trap you just triggered has run out of... whatever it tried to do to you. You doubt you'll be so lucky next time.

 Upon closer examination, the traps and safe tiles in this room seem to follow a pattern. The tiles are arranged into rows that are all the same width; you take note of the safe tiles (`.`) and traps (`^`) in the first row (your puzzle input).

 The type of tile (trapped or safe) in each row is based on the types of the tiles in the same position, and to either side of that position, in the previous row. (If either side is off either end of the row, it counts as "safe" because there isn't a trap embedded in the wall.)

 For example, suppose you know the first row (with tiles marked by letters) and want to determine the next row (with tiles marked by numbers):
````
 ABCDE
 12345
````

 The type of tile `2` is based on the types of tiles `A`, `B`, and `C`; the type of tile `5` is based on tiles `D`, `E`, and an imaginary "safe" tile. Let's call these three tiles from the previous row the **left**, **center**, and **right** tiles, respectively. Then, a new tile is a **trap** only in one of the following situations:

 * Its **left** and **center** tiles are traps, but its **right** tile is not.
 * Its **center** and **right** tiles are traps, but its **left** tile is not.
 * Only its **left** tile is a trap.
 * Only its **right** tile is a trap.
 
 In any other situation, the new tile is safe.

 Then, starting with the row `..^^.`, you can determine the next row by applying those rules to each new tile:

 * The leftmost character on the next row considers the left (nonexistent, so we assume "safe"), center (the first `.`, which means "safe"), and right (the second `.`, also "safe") tiles on the previous row. Because all of the trap rules require a trap in at least one of the previous three tiles, the first tile on this new row is also safe, `.`.
 * The second character on the next row considers its left (`.`), center (`.`), and right (`^`) tiles from the previous row. This matches the fourth rule: only the right tile is a trap. Therefore, the next tile in this new row is a trap, `^`.
 * The third character considers `.^^`, which matches the second trap rule: its center and right tiles are traps, but its left tile is not. Therefore, this tile is also a trap, `^`.
 * The last two characters in this new row match the first and third rules, respectively, and so they are both also traps, `^`.

 After these steps, we now know the next row of tiles in the room: `.^^^^`. Then, we continue on to the next row, using the same rules, and get `^^..^`. After determining two new rows, our map looks like this:

 ````
 ..^^.
 .^^^^
 ^^..^
 ````

 Here's a larger example with ten tiles per row and ten rows:

 ````
 .^^.^.^^^^
 ^^^...^..^
 ^.^^.^.^^.
 ..^^...^^^
 .^^^^.^^.^
 ^^..^.^^..
 ^^^^..^^^.
 ^..^^^^.^^
 .^^^..^.^^
 ^^.^^^..^^
 ````

 In ten rows, this larger example has `38` safe tiles.

 Starting with the map in your puzzle input, in a total of `40` rows (including the starting row), **how many safe tiles** are there?
 
 */
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

struct Row: CustomStringConvertible {
    let tiles: [Tile]

    init(_ tiles: [Tile]) {
        self.tiles = tiles
    }

    init(_ tiles: String) {
        self.tiles = tiles.toTiles()
    }

    func nextRow() -> Row {
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

    func safeTiles() -> Int {
        return tiles.reduce(0) { $0 + ($1 == .safe ? 1 : 0) }
    }

    var description: String {
        return tiles.map { $0.description }.joined()
    }
}

let example = Row("..^^.")
assert(example.nextRow().description == ".^^^^")
assert(example.nextRow().nextRow().description == "^^..^")

func part1(initial initialRow: Row, numRows: Int) -> Int {
    var row = initialRow, safeTiles = 0

    for _ in 0..<numRows {
        safeTiles += row.safeTiles()
        row = row.nextRow()
    }

    return safeTiles
}

assert(part1(initial: Row(".^^.^.^^^^"), numRows: 10) == 38)

let input = try readResourceFile("input.txt")

let part1Answer = part1(initial: Row(input), numRows: 40)
assert(part1Answer == 1963)


//: [Next](@next)
