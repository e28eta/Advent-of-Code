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
}

public struct Rope {
    var headPosition = Point(x: 0, y: 0)
    var tailPosition = Point(x: 0, y: 0)
    var allTailPositions = Set<Point>()

    public init() {
        allTailPositions.insert(tailPosition)
    }

    public mutating func apply(_ instruction: Instruction) {
        for _ in (0..<instruction.distance) {
            let oldHead = headPosition
            headPosition.step(instruction.direction)

            let newDistanceBetween = headPosition.manhattanDistance(to: tailPosition)

            // if I never step more than 1, I think these are the only two conditions that
            // cause tail to move, and tail will always move to the spot head just left
            if (newDistanceBetween == 3) ||
                (newDistanceBetween == 2 && headPosition.isSameRowOrCol(tailPosition)) {
                tailPosition = oldHead
                allTailPositions.insert(tailPosition)
            }
        }
    }

    public func tailPositionCount() -> Int {
        return allTailPositions.count
    }
}
