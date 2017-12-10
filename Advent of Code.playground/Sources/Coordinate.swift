import Foundation

public struct Coordinate: Equatable, Comparable, Hashable, CustomStringConvertible {
    public var x: Int, y: Int

    public init() {
        self.x = 0
        self.y = 0
    }

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public static func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    public static func <(lhs: Coordinate, rhs: Coordinate) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        } else {
            return lhs.y < rhs.y
        }
    }

    public var hashValue: Int {
        // assuming we're using small-ish values, I think this is efficient enough
        return (x << 16 + y).hashValue
    }

    public var description: String {
        return "(\(x), \(y))"
    }

    public func distance(to coordinate: Coordinate) -> Int {
        return diff(coordinate.x, x) + diff(coordinate.y, y)
    }

    public static func +(_ lhs: Coordinate, _ rhs: (Int, Int)) -> Coordinate {
        return Coordinate(x: lhs.x + rhs.0, y: lhs.y + rhs.1)
    }
}
