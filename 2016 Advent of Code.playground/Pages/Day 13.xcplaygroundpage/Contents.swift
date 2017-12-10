//: [Previous](@previous)

/*:
 # Day 13: A Maze of Twisty Little Cubicles

 You arrive at the first floor of this new building to discover a much less welcoming environment than the shiny atrium of the last one. Instead, you are in a maze of twisty little cubicles, all alike.

 Every location in this area is addressed by a pair of non-negative integers `(x,y)`. Each such coordinate is either a wall or an open space. You can't move diagonally. The cube maze starts at `0,0` and seems to extend infinitely toward **positive** `x` and `y`; negative values are **invalid**, as they represent a location outside the building. You are in a small waiting area at `1,1`.

 While it seems chaotic, a nearby morale-boosting poster explains, the layout is actually quite logical. You can determine whether a given `x,y` coordinate will be a wall or an open space using a simple system:

 * Find `x*x + 3*x + 2*x*y + y + y*y`.
 * Add the office designer's favorite number (your puzzle input).
 * Find the [binary representation](https://en.wikipedia.org/wiki/Binary_number) of that sum; count the **number** of [bits](https://en.wikipedia.org/wiki/Bit) that are `1`.
   * If the number of bits that are `1` is **even**, it's an **open space**.
   * If the number of bits that are `1` is **odd**, it's a **wall**.

 For example, if the office designer's favorite number were `10`, drawing walls as `#` and open spaces as `.`, the corner of the building containing `0,0` would look like this:

 ````
   0123456789
 0 .#.####.##
 1 ..#..#...#
 2 #....##...
 3 ###.#.###.
 4 .##..#..#.
 5 ..##....#.
 6 #...##.###
 ````

 Now, suppose you wanted to reach `7,4`. The shortest route you could take is marked as `O`:

 ````
   0123456789
 0 .#.####.##
 1 .O#..#...#
 2 #OOO.##...
 3 ###O#.###.
 4 .##OO#OO#.
 5 ..##OOO.#.
 6 #...##.###
 ````

 Thus, reaching `7,4` would take a minimum of `11` steps (starting from your current location, `1,1`).

 What is the fewest number of steps required for you to reach `31,39`?
 
 Your puzzle input is `1362`.
 */
import Foundation

enum Location: CustomStringConvertible {
    case wall, open

    var description: String {
        switch self {
        case .wall: return "#"
        case .open: return "."
        }
    }
}

struct BuildingCoordinate {
    let designerFavNumber: UInt
    let x: UInt, y: UInt

    init(designerFavNumber: UInt, x: UInt, y: UInt) {
        self.designerFavNumber = designerFavNumber
        self.x = x
        self.y = y
    }

    init(designerFavNumber: Int, x: Int, y: Int) {
        self.init(designerFavNumber: UInt(designerFavNumber), x: UInt(x), y: UInt(y))
    }

    func calculateNumber() -> UInt {
        return x*x + 3*x + 2*x*y + y + y*y
    }

    func location() -> Location {
        let number = calculateNumber() + designerFavNumber
        let popcount = number.popcount()

        return (popcount & 1) == 0 ? .open : .wall
    }
}

extension BuildingCoordinate: Hashable {
    static func ==(_ lhs: BuildingCoordinate, _ rhs: BuildingCoordinate) -> Bool {
        return lhs.designerFavNumber == rhs.designerFavNumber &&
            lhs.x == rhs.x && lhs.y == rhs.y
    }

    var hashValue: Int {
        return x.hashValue &* 31 &+ y.hashValue
    }
}

extension BuildingCoordinate: SearchState {
    func estimatedCost(toReach goal: BuildingCoordinate) -> Int {
        return Int(diff(goal.x, x) + diff(goal.y, y))
    }

    func adjacentStates() -> AnySequence<(cost: Int, state: BuildingCoordinate)> {
        var states = [
            (cost: 1, state: BuildingCoordinate(designerFavNumber: designerFavNumber, x: x + 1, y: y)),
            (cost: 1, state: BuildingCoordinate(designerFavNumber: designerFavNumber, x: x, y: y + 1))
        ]

        if x > 0 {
            states.append((cost: 1, state: BuildingCoordinate(designerFavNumber: designerFavNumber, x: x - 1, y: y)))
        }
        if y > 0 {
            states.append((cost: 1, state: BuildingCoordinate(designerFavNumber: designerFavNumber, x: x, y: y - 1)))
        }

        return AnySequence(states.filter { $0.state.location() == .open })
    }
}

struct Building {
    let number: Int
    let maxX: Int, maxY: Int

    func printBuilding(_ path: [BuildingCoordinate]? = nil, closedList: Set<BuildingCoordinate>? = nil) {
        print("  ", terminator: "")
        for x in 0...maxX {
            print(x % 10, terminator: "")
        }
        print("")
        for y in 0...maxY {
            print("\(y % 10) ", terminator: "")
            for x in 0...maxX {
                let c = BuildingCoordinate(designerFavNumber: number, x: x, y: y)

                if path?.contains(c) ?? false {
                    print("O", terminator: "")
                } else if closedList?.contains(c) ?? false {
                    print("x", terminator: "")
                } else {
                    print(c.location(), terminator: "")
                }
            }
            print("")
        }
    }
}

let exampleNumber = 10
let exampleStart = BuildingCoordinate(designerFavNumber: exampleNumber, x: 1, y: 1)
let exampleSearch = AStarSearch(initial: exampleStart,
                                goal: BuildingCoordinate(designerFavNumber: exampleNumber, x: 7, y: 4))
let examplePath = exampleSearch.shortestPath()

assert(examplePath?.cost == 11)

Building(number: exampleNumber, maxX: 9, maxY: 6).printBuilding(examplePath?.steps)

let part1Number = 1362
let part1Start = BuildingCoordinate(designerFavNumber: part1Number, x: 1, y: 1)
let part1 = AStarSearch(initial: part1Start,
                        goal: BuildingCoordinate(designerFavNumber: part1Number, x: 31, y: 39))
let part1Answer = part1.shortestPath()

//Building(number: part1Number, maxX: 50, maxY: 50).printBuilding(part1Answer?.steps)

assert(part1Answer?.cost == 82)

/*:
 # Part Two

 How many locations (distinct x,y coordinates, including your starting location) can you reach in at most 50 steps?
 */

class Step<State: SearchState>: Hashable {
    let state: State
    let cost: Int

    init(_ state: State, cost: Int) {
        self.state = state
        self.cost = cost
    }

    static func ==(_ lhs: Step<State>, _ rhs: Step<State>) -> Bool {
        return lhs.state == rhs.state && lhs.cost == rhs.cost
    }

    var hashValue: Int {
        return state.hashValue
    }
}

func locationsReachable<State: SearchState>(from initial: State, in maxCost: Int) -> [State] {
    var openList = Set<Step<State>>()
    var closedList = Set<State>()

    openList.insert(Step(initial, cost: 0))

    while let step = openList.popFirst() {
        if closedList.contains(step.state) {
            continue
        }

        closedList.insert(step.state)

        for adjacentState in step.state.adjacentStates() {
            let totalCost = adjacentState.cost + step.cost

            if totalCost <= maxCost {
                openList.insert(Step(adjacentState.state, cost: totalCost))
            }
        }
    }

    return Array(closedList)
}

assert(locationsReachable(from: exampleStart, in: 4).count == 9)

let part2Answer = locationsReachable(from: part1Start, in: 50).count
assert(part2Answer == 138)

//: [Next](@next)
