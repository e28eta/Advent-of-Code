//: [Previous](@previous)

import Foundation

/**
 --- Day 12: Rain Risk ---

 Your ferry made decent progress toward the island, but the storm came in faster than anyone expected. The ferry needs to take **evasive actions!**

 Unfortunately, the ship's navigation computer seems to be malfunctioning; rather than giving a route directly to safety, it produced extremely circuitous instructions. When the captain uses the PA system to ask if anyone can help, you quickly volunteer.

 The navigation instructions (your puzzle input) consists of a sequence of single-character **actions** paired with integer input **values.** After staring at them for a few minutes, you work out what they probably mean:

 - Action `N` means to move **north** by the given value.
 - Action `S` means to move **south** by the given value.
 - Action `E` means to move **east** by the given value.
 - Action `W` means to move **west** by the given value.
 - Action `L` means to turn **left** the given number of degrees.
 - Action `R` means to turn **right** the given number of degrees.
 - Action `F` means to move **forward** by the given value in the direction the ship is currently facing.

 The ship starts by facing **east**. Only the `L` and `R` actions change the direction the ship is facing. (That is, if the ship is facing east and the next instruction is `N10`, the ship would move north 10 units, but would still move east if the following action were `F`.)

 For example:

 ```
 F10
 N3
 F7
 R90
 F11
 ```

 These instructions would be handled as follows:

 - `F10` would move the ship 10 units east (because the ship starts by facing east) to **east 10, north 0.**
 - `N3` would move the ship 3 units north to **east 10, north 3.**
 - `F7` would move the ship another 7 units east (because the ship is still facing east) to **east 17, north 3.**
 - `R90` would cause the ship to turn right by 90 degrees and face **south;** it remains at **east 17, north 3.**
 - `F11` would move the ship 11 units south to **east 17, south 8.**

 At the end of these instructions, the ship's Manhattan distance (sum of the absolute values of its east/west position and its north/south position) from its starting position is `17 + 8` = `25`.

 Figure out where the navigation instructions lead. **What is the Manhattan distance between that location and the ship's starting position?**
 */

enum Direction: Character {
    case north = "N", east = "E", south = "S", west = "W"

    mutating func turn(direction: TurnDirection) {
        switch (self, direction) {
        case (.north, .right), (.south, .left): self = .east
        case (.north, .left), (.south, .right): self = .west
        case (.east, .left), (.west, .right): self = .north
        case (.east, .right), (.west, .left): self = .south
        }
    }

    func coordinateDelta() -> (x: Int, y: Int) {
        switch self {
        case .north: return (0, -1)
        case .south: return (0, 1)
        case .west: return (-1, 0)
        case .east: return (1, 0)
        }
    }
}

enum TurnDirection: Character {
    case right = "R", left = "L"

    func turn(waypoint: Coordinate) -> Coordinate {
        switch self {
        case .right:
            return Coordinate(x: waypoint.y * -1,
                              y: waypoint.x)
        case .left:
            return Coordinate(x: waypoint.y,
                              y: waypoint.x * -1)
        }
    }
}

extension Coordinate {
    var total: Int {
        return distance(to: .origin)
    }

    static func +=(_ lhs: inout Coordinate, _ rhs: (Direction, Int)) {
        let delta = rhs.0.coordinateDelta()

        let newValue = Coordinate(x: lhs.x + delta.x * rhs.1,
                                  y: lhs.y + delta.y * rhs.1)
        lhs = newValue
    }

    static func *(_ lhs: Coordinate, _ rhs: Int) -> (Int, Int) {
        return (lhs.x * rhs, lhs.y * rhs)
    }
}

enum Action {
    case absoluteMovement(Direction, distance: Int)
    case turn(TurnDirection, times: Int)
    case moveForward(distance: Int)

    init?(_ string: String) {
        guard let command = string.first,
              let value = Int(string.dropFirst()) else {
            return nil
        }

        if let direction = Direction(rawValue: command) {
            self = .absoluteMovement(direction, distance: value)
        } else if let direction = TurnDirection(rawValue: command), value % 90 == 0 {
            self = .turn(direction, times: value / 90)
        } else if command == "F" {
            self = .moveForward(distance: value)
        } else {
            return nil
        }
    }
}

struct Position {
    var currentDirection = Direction.east
    var coordinate = Coordinate()
    var waypoint = Coordinate(x: 10, y: -1)

    func taking(actions: [Action]) -> Position {
        var position = self
        for action in actions {
            position.take(action: action)
        }
        return position
    }

    mutating func take(action: Action) {
        switch action {
        case let .absoluteMovement(direction, distance: distance):
            coordinate += (direction, distance)
        case let .moveForward(distance: distance):
            coordinate += (currentDirection, distance)
        case let .turn(direction, times: times):
            for _ in (0..<times) {
                currentDirection.turn(direction: direction)
            }
        }
    }

    mutating func take(partTwo action: Action) {
        switch action {
        case let .absoluteMovement(direction, distance: distance):
            waypoint += (direction, distance)
        case let .moveForward(distance: distance):
            coordinate = coordinate + (waypoint * distance)
        case let .turn(direction, times: times):
            for _ in (0..<times) {
                waypoint = direction.turn(waypoint: waypoint)
            }
        }
    }
}


let exampleInput = """
F10
N3
F7
R90
F11
""".lines().compactMap(Action.init)

let input = try readResourceFile("input.txt").lines().compactMap(Action.init)

verify([
    (exampleInput, 25),
    (input, 1601),
]) { actions in
    Position().taking(actions: actions).coordinate.distance(to: .origin)
}

/**
 --- Part Two ---

 Before you can give the destination to the captain, you realize that the actual action meanings were printed on the back of the instructions the whole time.

 Almost all of the actions indicate how to move a waypoint which is relative to the ship's position:

 - Action `N` means to move the waypoint **north** by the given value.
 - Action `S` means to move the waypoint **south** by the given value.
 - Action `E` means to move the waypoint **east** by the given value.
 - Action `W` means to move the waypoint **west** by the given value.
 - Action `L` means to rotate the waypoint around the ship **left (counter-clockwise)** the given number of degrees.
 - Action `R` means to rotate the waypoint around the ship **right (clockwise)** the given number of degrees.
 - Action `F` means to move **forward** to the waypoint a number of times equal to the given value.

 The waypoint starts **10 units east and 1 unit north** relative to the ship. The waypoint is relative to the ship; that is, if the ship moves, the waypoint moves with it.

 For example, using the same instructions as above:

 - `F10` moves the ship to the waypoint 10 times (a total of **100 units east and 10 units north**), leaving the ship at **east 100, north 10.** The waypoint stays 10 units east and 1 unit north of the ship.
 - `N3` moves the waypoint 3 units north to **10 units east and 4 units north of the ship.** The ship remains at **east 100, north 10.**
 - `F7` moves the ship to the waypoint 7 times (a total of **70 units east and 28 units north**), leaving the ship at east **170, north 38.** The waypoint stays 10 units east and 4 units north of the ship.
 - `R90` rotates the waypoint around the ship clockwise 90 degrees, moving it to **4 units east and 10 units south of the ship.** The ship remains at **east 170, north 38.**
 - `F11` moves the ship to the waypoint 11 times (a total of **44 units east and 110 units south**), leaving the ship at **east 214, south 72.** The waypoint stays 4 units east and 10 units south of the ship.

 After these operations, the ship's Manhattan distance from its starting position is `214 + 72` = `286`.

 Figure out where the navigation instructions actually lead. **What is the Manhattan distance between that location and the ship's starting position?**
 */

verify([
    (exampleInput, 286),
    (input, 13340)
]) { actions in
    actions.reduce(into: Position()) { position, action in
        position.take(partTwo: action)
    }.coordinate.distance(to: .origin)
}

//: [Next](@next)
