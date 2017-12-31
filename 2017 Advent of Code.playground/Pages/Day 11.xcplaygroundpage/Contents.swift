//: [Previous](@previous)

/*:
 # Day 11: Hex Ed

 Crossing the bridge, you've barely reached the other side of the stream when a program comes up to you, clearly in distress. "It's my child process," she says, "he's gotten lost in an infinite grid!"

 Fortunately for her, you have plenty of experience with infinite grids.

 Unfortunately for you, it's a [hex grid](https://en.wikipedia.org/wiki/Hexagonal_tiling).

 The hexagons ("hexes") in this grid are aligned such that adjacent hexes can be found to the north, northeast, southeast, south, southwest, and northwest:

 ```
   \ n  /
 nw +--+ ne
   /    \
 -+      +-
   \    /
 sw +--+ se
   / s  \
 ```

 You have the path the child process took. Starting where he started, you need to determine the fewest number of steps required to reach him. (A "step" means to move from the hex you are in to any adjacent hex.)

 For example:

 - `ne,ne,ne` is `3` steps away.
 - `ne,ne,sw,sw` is `0` steps away (back where you started).
 - `ne,ne,s,s` is `2` steps away (`se,se`).
 - `se,sw,se,sw,sw` is `3` steps away (`s,s,sw`).
 */

import Foundation

enum Direction: String {
    case nw, n, ne, sw, s, se

    var distance: Distance {
        let x: Int, y: Int
        switch self {
        case .nw, .sw: x = -1
        case .ne, .se: x = 1
        case .n, .s: x = 0
        }
        switch self {
        case .n: y = 2
        case .nw, .ne: y = 1
        case .sw, .se: y = -1
        case .s: y = -2
        }

        return Distance(x: x, y: y)
    }

    static func parse(_ string: String) -> [Direction] {
        return string.components(separatedBy: ",").flatMap { Direction(rawValue: $0) }
    }
}

struct Distance {
    let x: Int
    let y: Int

    static func +(lhs: Distance, rhs: Distance) -> Distance {
        return Distance(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static var zero: Distance { return Distance(x: 0, y: 0) }

    var stepsNecessary: Int {
        let absX = abs(x), absY = abs(y)

        if absX >= absY {
            // combination of steps in X direction can also hone in on necessary Y
            return absX
        } else {
            let extra = (absY - absX).quotientAndRemainder(dividingBy: 2)
            assert(extra.remainder == 0)
            return absX + extra.quotient
        }
    }
}

let testData = [
    ("ne,ne,ne", 3),
    ("ne,ne,sw,sw", 0),
    ("ne,ne,s", 2),
    ("ne,ne,s,s", 2),
    ("se,sw,se,sw,sw", 3),
]

verify(testData) {
    Direction.parse($0).map { $0.distance }.reduce(Distance.zero, +).stepsNecessary
}

let input = try readResourceFile("input.txt")
let directions = Direction.parse(input)
assertEqual(directions.map { $0.distance }.reduce(Distance.zero, +).stepsNecessary, 764)


/*:

 */

//: [Next](@next)
