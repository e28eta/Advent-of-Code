//: [Previous](@previous)

import Foundation

/*:
 # Day 3: Spiral Memory

 You come across an experimental new kind of memory stored on an infinite two-dimensional grid.

 Each square on the grid is allocated in a spiral pattern starting at a location marked `1` and then counting up while spiraling outward. For example, the first few squares are allocated like this:

 ```
 17  16  15  14  13
 18   5   4   3  12
 19   6   1   2  11
 20   7   8   9  10
 21  22  23---> ...
 ```

 While this is very space-efficient (no squares are skipped), requested data must be carried back to square `1` (the location of the only access port for this memory system) by programs that can only move up, down, left, or right. They always take the shortest path: the [Manhattan Distance](https://en.wikipedia.org/wiki/Taxicab_geometry) between the location of the data and square `1`.

 For example:

 - Data from square `1` is carried `0` steps, since it's at the access port.
 - Data from square `12` is carried `3` steps, such as: down, left, left.
 - Data from square `23` is carried only `2` steps: up twice.
 - Data from square `1024` must be carried `31` steps.

 How many steps are required to carry the data from the square identified in your puzzle input all the way to the access port?

 Your puzzle input is `325489`.
 */

let testData = [
    (1, 0),
    (12, 3),
    (23, 2),
    (1024, 31),
]

let input = 325489

/*
 ...1^2 == 0
 ...3^2 == [1: [2, 4, 6, 8], 2: [...]]
 ...5^2 == [2: [11, 15, 19, 23], 3: [2 +- 1], 4: [3, in same dir]]
 ...7^2 == [3: [28, 34, 40, 46], 4, 5, 6]

 The direct paths go up by 2, 4, 6 each time, with a difference of the root between last & next

 There are `P=(n^2 - (n-1)^2)` numbers around the perimeter. Can find which side X
 is on based on dividing `C=P/4` (treating corners as only belonging to a single side)
 and `S=(X - (n-1)^2)/C` (rounded down, where 0 = right, 1 = top, etc)
 */

let N = sqrt(9)

struct SpiralMemoryLocation: CustomStringConvertible {
    /// The identifier for this square/location
    let square: Int

    /// Which ring contains the memory square for this location?
    let ring: Int
    /// What is the previous ring?
    var previousRing: Int { return max(ring - 2, 0) }

    /// The largest numbered square in this ring
    var largestNumber: Int { return Int(pow(Double(ring), 2)) }
    /// The smallest numbered square in this ring
    var smallestNumber: Int { return Int(pow(Double(previousRing), 2) + 1) }

    /// How many steps out from the access port is this ring?
    var radius: Int { return (ring - 1) / 2 }

    /// Represents the four sides of the spiral
    enum Side: Int {
        case right = 0, top, left, bottom
    }
    /// Which side of the spiral is this square on?
    var side: Side { return Side(rawValue: (square - smallestNumber) / max(ring - 1, 1))! }
    /// Counting from the smallest number on this side as 0, what position does this square hold?
    var position: Int { return (square - smallestNumber) % max(ring - 1, 1) }

    var offsetFromCenter: Int {
        return position - (previousRing / 2)
    }

    var distanceFromCenter: Int {
        return radius + abs(offsetFromCenter)
    }

    init(for x: Int) {
        precondition(x > 0, "x must be positive")

        self.square = x

        let s = sqrt(Double(x))
        let candidate = Int(ceil(s))

        if candidate % 2 == 1 {
            // odd number, fine as-is
            ring = candidate
        } else {
            // even number, need to round up to next odd
            ring = candidate + 1
        }
    }

    var description: String {
        return "{ radius: \(radius), ring: \(ring), range:\(smallestNumber)...\(largestNumber), side: \(side), position: \(position), offset: \(offsetFromCenter) }"
    }


}

verify(testData, { SpiralMemoryLocation(for: $0).distanceFromCenter })

let location = SpiralMemoryLocation(for: input)
assertEqual(location.distanceFromCenter, 552)

/*:
 # Part Two

 As a stress test on the system, the programs here clear the grid and then store the value `1` in square `1`. Then, in the same allocation order as shown above, they store the sum of the values in all adjacent squares, including diagonals.

 So, the first few squares' values are chosen as follows:

 * Square `1 starts with the value `1`.
 * Square `2` has only one adjacent filled square (with value `1`), so it also stores `1`.
 * Square `3` has both of the above squares as neighbors and stores the sum of their values, `2`.
 * Square `4` has all three of the aforementioned squares as neighbors and stores the sum of their values, `4`.
 * Square 5 only has the first and fourth squares as neighbors, so it gets the value `5`.

 Once a square is written, its value does not change. Therefore, the first few squares would receive the following values:

 ```
 147  142  133  122   59
 304    5    4    2   57
 330   10    1    1   54
 351   11   23   25   26
 362  747  806--->   ...
 ```

 What is the first value written that is larger than your puzzle input?
 */

//: [Next](@next)
