import Foundation

enum Direction {
    case up, down, left, right

    init?(_ string: some StringProtocol) {
        switch string {
        case "U": self = .up
        case "D": self = .down
        case "L": self = .left
        case "R": self = .right
        default: return nil
        }
    }
}

public struct Instruction {
    let direction: Direction
    let distance: Int

    public init?(_ string: String) {
        guard let (dir, dist) = string.splitOnce(separator: " "),
              let direction = Direction(dir),
              let distance = Int(dist) else {
            return nil
        }
        self.direction = direction
        self.distance = distance
    }
}

public struct Point: CustomStringConvertible, Hashable {
    public var x: Int, y: Int

    public init(x: Int, y: Int) { self.x = x; self.y = y }
    public var description: String { return "\(x), \(y)" }

    func manhattanDistance(to other: Point) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }

    func isSameRowOrCol(_ other: Point) -> Bool {
        return x == other.x || y == other.y
    }

    mutating func step(_ direction: Direction) {
        switch direction {
        case .up:
            y -= 1
        case .down:
            y += 1
        case .left:
            x -= 1
        case .right:
            x += 1
        }
    }

    mutating func step(_ other: Point) {
        let distanceToOther = manhattanDistance(to: other)
        guard distanceToOther > 2 || (distanceToOther == 2 && isSameRowOrCol(other)) else { return }

        // this takes 2 steps (a diagonal step) if neither x nor y are equal
        // this only takes one step if we're in the same row or column
        // other cases shouldn't happen due to other logic

        if x < other.x {
            x += 1
        } else if x > other.x {
            x -= 1
        }

        if y < other.y {
            y += 1
        } else if y > other.y {
            y -= 1
        }
    }
}

public struct Rope {
    var positions: Array<Point>
    var allTailPositions = Set<Point>()

    public init(length: Int = 2) {
        precondition(length >= 2)

        positions = Array(repeating: Point(x: 0, y: 0), count: length)
        allTailPositions.insert(positions.last!)
    }

    public mutating func apply(_ instruction: Instruction) {
        for _ in (0..<instruction.distance) {
            positions[0].step(instruction.direction)

            for idx in positions.indices.dropFirst() {
                positions[idx].step(positions[idx - 1])
            }
            allTailPositions.insert(positions.last!)
        }
    }

    public func tailPositionCount() -> Int {
        return allTailPositions.count
    }
}
