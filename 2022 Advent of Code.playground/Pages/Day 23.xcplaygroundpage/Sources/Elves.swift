import Foundation

public enum Direction: CaseIterable {
    // north is positive y, east is positive x
    case north, south, west, east
}

public struct Point: CustomStringConvertible, Hashable {
    public var x: Int, y: Int

    public init(x: Int, y: Int) { self.x = x; self.y = y }
    public var description: String { return "\(x), \(y)" }

    public static func +(_ point: Point, _ direction: Direction) -> Point {
        switch direction {
        case .north:
            return Point(x: point.x, y: point.y + 1)
        case .south:
            return Point(x: point.x, y: point.y - 1)
        case .west:
            return Point(x: point.x - 1, y: point.y)
        case .east:
            return Point(x: point.x + 1, y: point.y)
        }
    }

    public static func +(_ point: Point, _ xy: (Int, Int)) -> Point {
        return Point(x: point.x + xy.0, y: point.y + xy.1)
    }

    public func adjacent() -> [Point] {
        return (-1 ... 1).flatMap { deltaY in
            (-1 ... 1).compactMap { deltaX in
                if deltaX == 0 && deltaY == 0 { return nil }
                return Point(x: x + deltaX, y: y + deltaY)
            }
        }
    }

    public func adjacent(in direction: Direction) -> [Point] {
        switch direction {
        case .north:
            return [self + (-1, 1), self + (0, 1), self + (1, 1)]
        case .south:
            return [self + (-1, -1), self + (0, -1), self + (1, -1)]
        case .west:
            return [self + (-1, -1), self + (-1, 0), self + (-1, 1)]
        case .east:
            return [self + (1, -1), self + (1, 0), self + (1, 1)]
        }
    }
}

public struct ElfGroup {
    public var elfLocations: Set<Point>

    public init(_ string: String) {
        elfLocations = string.lines()
            .reversed()
            .enumerated()
            .flatMap { (y, line) in
                line.enumerated()
                    .filter { (_, c) in
                        c == Character("#")
                    }
                    .map { (x, _) in
                        Point(x: x, y: y)
                    }
            }
            .reduce(into: Set()) { (set, point) in
                set.insert(point)
            }
    }

    public mutating func part1() -> Int {
        for roundNum in 0 ..< 10 {
            _ = calculate(roundNum: roundNum)
        }

        let xRange = elfLocations.map(\.x).minAndMax()!
        let yRange = elfLocations.map(\.y).minAndMax()!

        // area covered minus num elves
        return ((1 + xRange.max - xRange.min)
                * (1 + yRange.max - yRange.min)
                - elfLocations.count)
    }

    public mutating func part2() -> Int {
        return 1 + (0...).first { roundNum in
            false == calculate(roundNum: roundNum)
        }!
    }

    mutating func calculate(roundNum: Int) -> Bool {
        var elfWantedToMove = false

        let directions = Direction.allCases.rotated(shiftingToStart: roundNum % Direction.allCases.count)

        let candidateDirections = elfLocations.reduce(into: [Point: [Point]]()) { (destinations, location) in
            var targetLocation = location

            if location.adjacent().contains(where: elfLocations.contains) {
                elfWantedToMove = true
                // at least one adjacent square contains an elf
                // find a valid direction to move in

                if let direction = directions.first(where: {
                    elfLocations.isDisjoint(with: location.adjacent(in: $0))
                }) {
                    targetLocation = location + direction
                }
            }

            destinations[targetLocation, default: []].append(location)
        }

        elfLocations = candidateDirections.reduce(into: Set()) { set, targetAndSources in
            if targetAndSources.value.count == 1 {
                // only one elf wants to move here
                set.insert(targetAndSources.key)
            } else {
                // more than one elf wanted to move into the same spot, they stay put
                set.formUnion(targetAndSources.value)
            }
        }

        return elfWantedToMove
    }


}
