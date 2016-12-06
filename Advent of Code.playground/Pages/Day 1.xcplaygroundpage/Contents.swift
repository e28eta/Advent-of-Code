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

struct Position {
    var currentDirection: Direction
    var northSouthDistance: Int
    var eastWestDistance: Int

    init() {
        currentDirection = .North
        northSouthDistance = 0
        eastWestDistance = 0
    }

    func taking(steps: [Step]) -> Position {
        var position = self
        for step in steps {
            position.take(step: step)
        }
        return position
    }

    mutating func take(step: Step) {
        currentDirection = currentDirection.turning(step.direction)

        switch currentDirection {
        case .North: northSouthDistance += step.distance
        case .South: northSouthDistance -= step.distance
        case .East: eastWestDistance += step.distance
        case .West: eastWestDistance -= step.distance
        }
    }

    var totalDistanceFromStart: Int {
        return abs(eastWestDistance) + abs(northSouthDistance)
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
        return try Position().taking(steps: Step.parse(steps: steps)).totalDistanceFromStart
    } catch {
        return -1
    }
}

assert(totalDistance("R2, L3") == 5)
assert(totalDistance("R2, R2, R2") == 2)
assert(totalDistance("R5, L5, R5, R3") == 12)


let stepsString = try readResourceFile("input.txt")

// Part 1 answer:
totalDistance(stepsString)



//: [Next](@next)
