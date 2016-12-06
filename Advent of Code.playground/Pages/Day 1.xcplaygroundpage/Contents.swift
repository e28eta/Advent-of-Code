/*:
 # Day 1: No Time for a Taxicab

 Santa's sleigh uses a very high-precision clock to guide its movements, and the clock's oscillator is regulated by stars. Unfortunately, the stars have been stolen... by the Easter Bunny. To save Christmas, Santa needs you to retrieve all **fifty stars** by December 25th.

 Collect stars by solving puzzles. Two puzzles will be made available on each day in the advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants **one star**. Good luck!

 You're airdropped near Easter Bunny Headquarters in a city somewhere. "Near", unfortunately, is as close as you can get - the instructions on the Easter Bunny Recruiting Document the Elves intercepted start here, and nobody had time to work them out further.

 The Document indicates that you should start at the given coordinates (where you just landed) and face North. Then, follow the provided sequence: either turn left (`L`) or right (`R`) 90 degrees, then walk forward the given number of blocks, ending at a new intersection.

 There's no time to follow such ridiculous instructions on foot, though, so you take a moment and work out the destination. Given that you can only walk on the [street grid of the city](https://en.wikipedia.org/wiki/Taxicab_geometry), how far is the shortest path to the destination?

 For example:

 * Following `R2, L3` leaves you `2` blocks East and `3` blocks North, or `5` blocks away.
 * `R2, R2, R2` leaves you `2` blocks due South of your starting position, which is `2` blocks away.
 * `R5, L5, R5, R3` leaves you `12` blocks away.

 **How many blocks away** is Easter Bunny HQ?
 */

import Foundation

enum Direction {
    case North, East, South, West

    func turning(_ direction: Turn) -> Direction {
        switch (self, direction) {
        case (.North, .Right), (.South, .Left): return .East
        case (.North, .Left), (.South, .Right): return .West
        case (.East, .Left), (.West, .Right): return .North
        case (.East, .Right), (.West, .Left): return .South
        }
    }
}

enum Turn: String {
    case Right = "R", Left = "L"
}

struct Coordinate: Hashable {
    var northSouth: Int
    var eastWest: Int

    init() {
        northSouth = 0
        eastWest = 0
    }

    var total: Int {
        return abs(northSouth) + abs(eastWest)
    }

    static func ==(_ lhs: Coordinate, _ rhs: Coordinate) -> Bool {
        return lhs.northSouth == rhs.northSouth && lhs.eastWest == rhs.eastWest
    }

    var hashValue: Int {
        // expect to cluster around zero, so this is probably fine
        return (northSouth << 16 + eastWest).hashValue
    }
}

struct Position {
    var currentDirection: Direction
    var distance: Coordinate

    init() {
        currentDirection = .North
        distance = Coordinate()
    }

    func taking(steps: [Step]) -> Position {
        var position = self
        for step in steps {
            position.take(step: step)
        }
        return position
    }

    mutating func take(step: Step) -> [Coordinate] {
        var visitedCoordinates: [Coordinate] = []
        currentDirection = currentDirection.turning(step.direction)

        for _ in (0..<step.distance) {
            switch currentDirection {
            case .North: distance.northSouth += 1
            case .South: distance.northSouth -= 1
            case .East: distance.eastWest += 1
            case .West: distance.eastWest -= 1
            }

            visitedCoordinates.append(distance)
        }

        return visitedCoordinates
    }
}

struct Step: CustomStringConvertible {
    let direction: Turn
    let distance: Int

    static func parse(steps: String) throws -> [Step] {
        return try steps.components(separatedBy: ",").map { try Step($0) }
    }

    init(_ step: String) throws {
        var step = step.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dir = step.characters.first,
            let direction = Turn(rawValue: String(dir)),
            let distance = Int(String(step.characters.dropFirst(1)), radix: 10) else {
                print("Error parsing '\(step)'")
                throw NSError()
        }

        self.direction = direction
        self.distance = distance
    }

    var description: String {
        return "\(direction.rawValue)\(distance)"
    }
}

func totalDistance(_ steps: String) -> Int {
    do {
        return try Position().taking(steps: Step.parse(steps: steps)).distance.total
    } catch {
        return -1
    }
}

assert(totalDistance("R2, L3") == 5)
assert(totalDistance("R2, R2, R2") == 2)
assert(totalDistance("R5, L5, R5, R3") == 12)


let stepsString = try readResourceFile("input.txt")

// Part 1 answer:
let part1Answer = totalDistance(stepsString)

assert(part1Answer == 353) // now that we know it, check for regressions

/*:
 # Part Two

 Then, you notice the instructions continue on the back of the Recruiting Document. Easter Bunny HQ is actually at the first location you visit twice.

 For example, if your instructions are `R8, R4, R4, R8`, the first location you visit twice is `4` blocks away, due East.

 How many blocks away is the **first location you visit twice**?
 */

func distanceToFirstRepeatedLocation(_ steps: String) -> Int {
    var visitedCoordinates = Set<Coordinate>()
    var position = Position()
    var repeatedCoordinate: Coordinate? = nil

    visitedCoordinates.insert(position.distance)

    do {
        let steps = try Step.parse(steps: steps)

        eachStep: for step in steps {
            for coordinate in position.take(step: step) {
                if visitedCoordinates.insert(coordinate).inserted == false {
                    repeatedCoordinate = coordinate
                    break eachStep
                }
            }
        }

        if let repeatedCoordinate = repeatedCoordinate {
            return repeatedCoordinate.total
        } else {
            return -1
        }
    } catch {
        return -1
    }
}


assert(distanceToFirstRepeatedLocation("R8, R4, R4, R8") == 4)

let part2Answer = distanceToFirstRepeatedLocation(stepsString)

assert(part2Answer == 152)

//: [Next](@next)
