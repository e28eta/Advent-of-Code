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

struct SpiralMemoryRing {
    /// The identifier for this ring
    let ring: Int
    
    /// What is the previous ring?
    var previousRing: Int { return max(ring - 2, 0) }
    /// What is the next ring?
    var nextRing: Int { return ring + 2 }
    
    /// The largest numbered square in this ring
    var largestNumber: Int { return Int(pow(Double(ring), 2)) }
    /// The smallest numbered square in this ring
    var smallestNumber: Int { return Int(pow(Double(previousRing), 2) + 1) }

    /// How many steps out from the access port is this ring?
    var radius: Int { return (ring - 1) / 2 }

    /// How many elements on each side. The last one will be one less than this
    var sideLength: Int { return max(ring - 1, 1) }
    
    var offsetRange: CountableClosedRange<Int> { return -1...2 }
}

struct SpiralMemoryLocation<T> {
    /// The identifier for this square/location
    let square: Int
    /// The contents of this square
    let contents: T?
    
    /// Which ring contains the memory square for this location?
    let ring: SpiralMemoryRing
    
    /// Represents the four sides of the spiral
    enum Side: Int {
        case right = 0, top, left, bottom
    }
    /// Which side of the spiral is this square on?
    var side: Side { return Side(rawValue: (square - ring.smallestNumber) / ring.sideLength)! }
    /// Counting from the smallest number on this side as 0, what position does this square hold?
    var position: Int { return (square - ring.smallestNumber) % ring.sideLength }
    /// Is this a corner square?

    var offsetFromCenter: Int {
        return position - (ring.previousRing / 2)
    }

    var distanceFromCenter: Int {
        return ring.radius + abs(offsetFromCenter)
    }

    init(for x: Int, with contents: T? = nil) {
        precondition(x > 0, "x must be positive")

        self.square = x

        let s = sqrt(Double(x))
        let candidate = Int(ceil(s))

        if candidate % 2 == 1 {
            // odd number, fine as-is
            ring = SpiralMemoryRing(ring: candidate)
        } else {
            // even number, need to round up to next odd
            ring = SpiralMemoryRing(ring: candidate + 1)
        }
        self.contents = contents
    }
}

verify(testData, { SpiralMemoryLocation<Void>(for: $0).distanceFromCenter })

let location = SpiralMemoryLocation<Void>(for: input)
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

extension SpiralMemoryLocation.Side {
    func previous() -> SpiralMemoryLocation.Side {
        switch self {
        case .right: return .bottom
        case .top: return .right
        case .left: return .top
        case .bottom: return .left
        }
    }
        
    func next() -> SpiralMemoryLocation.Side {
        switch self {
        case .right: return .top
        case .top: return .left
        case .left: return .bottom
        case .bottom: return .right
        }
    }
}

enum SpiralNeighbor {
    case inward, outward, clockwise, counterclockwise
    case clockwiseInward, clockwiseOutward, counterclockwiseInward, counterclockwiseOutward
    
    static var all: [SpiralNeighbor] {
        return [
            .clockwiseInward, .inward, .counterclockwiseInward,
            .clockwise, .counterclockwise,
            .clockwiseOutward, .outward, .counterclockwiseOutward
        ]
    }
}

extension SpiralMemoryLocation {
    init(ring: Int, side: Side, position: Int, contents: T? = nil) {
        precondition(ring > 0, "Cannot have a ring less than 1")
        
        guard ring > 1 else {
            self = SpiralMemoryLocation(for: 1)
            return
        }
        
        let memoryRing = SpiralMemoryRing(ring: ring)
        switch position {
        case 0..<memoryRing.sideLength:
            // This is in-bounds for the ring
            self.ring = memoryRing
                // figure out where this falls on the ring
            self.square = memoryRing.smallestNumber + side.rawValue * memoryRing.sideLength + position
            self.contents = contents
        case -1:
            // Wrapped to previous side
            self = SpiralMemoryLocation(ring: ring, side: side.previous(), position: memoryRing.sideLength - 1)
        default:
            precondition((-1 ..< memoryRing.sideLength).contains(position))
            fatalError()
        }
    }
    
    func allNeighbors() -> [SpiralMemoryLocation] {
        return SpiralNeighbor.all.map { neighboringLocation(for: $0)}
    }
    
    func neighboringLocation(for neighbor: SpiralNeighbor) -> SpiralMemoryLocation {
        if ring.ring == 1 {
            // just use Neighbor.all as a convenient way to number these, adjust for access port = 1, and counting starting at 1 instead of 0
            return SpiralMemoryLocation(for: SpiralNeighbor.all.index(of: neighbor)! + 2)
        }
        
        // YUCK! Have to adjust for the corners, and the ones adjacent to corners. Luckily that's only 3
        // different squares, since each corner is canonically on the side where it has the highest position
        switch neighbor {
        case .clockwise:
            return SpiralMemoryLocation(ring: ring.ring, side: side, position: position - 1)
        case .clockwiseOutward:
            return SpiralMemoryLocation(ring: ring.nextRing, side: side, position: position)
        case .outward:
            return SpiralMemoryLocation(ring: ring.nextRing, side: side, position: position + 1)
        case .counterclockwiseOutward:
            return SpiralMemoryLocation(ring: ring.nextRing, side: side, position: position + 2)
        case .counterclockwise where position == ring.sideLength - 1:
            return SpiralMemoryLocation(ring: ring.nextRing, side: side.next(), position: 0)
        case .counterclockwise:
            return SpiralMemoryLocation(ring: ring.ring, side: side, position: position + 1)
        case .counterclockwiseInward where position == ring.sideLength - 1:
            return SpiralMemoryLocation(ring: ring.nextRing, side: side.next(), position: 1)
        case .counterclockwiseInward where position == ring.sideLength - 2:
            return SpiralMemoryLocation(ring: ring.ring, side: side.next(), position: 0)
        case .counterclockwiseInward:
            return SpiralMemoryLocation(ring: ring.previousRing, side: side, position: position)
        case .inward where position == ring.sideLength - 1:
            return SpiralMemoryLocation(ring: ring.ring, side: side.next(), position: 0)
        case .inward:
            return SpiralMemoryLocation(ring: ring.previousRing, side: side, position: position - 1)
        case .clockwiseInward where position == 0:
            return SpiralMemoryLocation(ring: ring.ring, side: side.previous(), position: ring.sideLength - 2)
        case .clockwiseInward:
            return SpiralMemoryLocation(ring: ring.previousRing, side: side, position: position - 2)
        }
    }
}

extension SpiralMemoryLocation.Side: CustomStringConvertible {
    var description: String { 
        switch self {
        case .right: return ".right"
        case .top: return ".top"
        case .left: return ".left"
        case .bottom: return ".bottom"
        }
    }
}
extension SpiralMemoryLocation: CustomStringConvertible {
    var description: String { return "(\(square): \(contents))" }
}


/*
 15 14 13 30
 04  3 12 29
 01  2 11 28
 08  9 10 27
 23 24 25 26
 */
let two = SpiralMemoryLocation<Void>(for: 2)
let three = SpiralMemoryLocation<Void>(for: 3)
let eleven = SpiralMemoryLocation<Void>(for: 11)
assert([8, 1, 4, 9, 3, 10, 11, 12] == two.allNeighbors().map { $0.square })
assert([1, 4, 15, 2, 14, 11, 12, 13] == three.allNeighbors().map { $0.square })
assert([9, 2, 3, 10, 12, 27, 28, 29] == eleven.allNeighbors().map { $0.square })

// incrementally build up indexed list of locations, use populated locations
// to calculate the next one, keep going until a memory location's contents exceeds `input` 
struct SpiralMemory<T> {
    /// Memory, indexed by the square number
    var memory: [Int: SpiralMemoryLocation<T>]
    /// closure to generate the contents of the next square. Parameters are (self, square)
    var contentsGenerator: (SpiralMemory<T>, Int) -> T
    
    init(contentsGenerator: @escaping (SpiralMemory<T>, Int) -> T) {
        memory = [:]
        self.contentsGenerator = contentsGenerator
    }
    
    mutating func generate(until test: (SpiralMemoryLocation<T>) -> Bool) -> SpiralMemoryLocation<T> {
        let location = (1...).first { n in 
            let next = SpiralMemoryLocation(for: n, with: contentsGenerator(self, n))
            memory[n] = next
            return test(next)
        }
        
        return memory[location!]!
    }
}

var testMemory = SpiralMemory<Int>() { testMemory, n in n * 2 }
testMemory.generate(until: { $0.square > 12 })
print(testMemory.memory.values.sorted { $0.square < $1.square })

var part2Memory = SpiralMemory<Int>() { mem, n in 
    if n == 1 { return 1 }
    return SpiralMemoryLocation<Void>(for: n).allNeighbors().reduce(0) { $0 + (mem.memory[$1.square]?.contents ?? 0) }
}

let part2Answer = part2Memory.generate(until: { $0.contents! > input })
assertEqual(330785, part2Answer.contents)

//: [Next](@next)
