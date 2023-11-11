import Foundation

public enum Contents {
    // modeling walls makes the logic a little easier,
    // or could use Bool and pre-seed more starting states
    // (wait at entrance for t=0...lcm)
    case wall, empty, blizzard
}

public struct Valley {
    public let space: Grid2DTime<Contents>

    public init(_ string: String) {
        let walls = string.lines().map { line in
            line.map { char in
                char == "#" ? Contents.wall : .empty
            }
        }

        // blizzard loops around inside of the walls, trim the
        // walls from those strings and construct the Blizzard
        let insideOfWalls = string.lines()
            .lazy
            .dropFirst()
            .dropLast()
            .map {
                $0.lazy.dropFirst().dropLast()
            }

        let blizzard = Blizzard(insideOfWalls)

        // add x/y back in for the walls
        let xRange = blizzard.xRange.expand(lower: 1, upper: 1)
        let yRange = blizzard.yRange.expand(lower: 1, upper: 1)
        // figure out the amount of time till the blizzard state loops
        let tRange = (0 ..< lcm(blizzard.xRange.count, blizzard.yRange.count))

        space = Grid2DTime(xRange: xRange, yRange: yRange, tRange: tRange, element: { x, y, t in
            guard blizzard.xRange.contains(x) && blizzard.yRange.contains(y) else {
                // must be in the outer area for the walls, adjust the indexes & return
                return walls[y + 1][x + 1]
            }

            return blizzard.isSnowing(x: x, y: y, t: t) ? .blizzard : .empty
        })
    }

    public func fastestPath() -> Int {
        let startLocation = space.startIndex.advanced(by: 1)
        let goalLocations = [space.endIndex.advanced(by: -2).coordinate.withoutTime()]

        let search = AStarSearch(initial: ValleySearchState(space: space, location: startLocation, remainingGoals: goalLocations),
                                 goal: .none)

        guard let (cost, _) = search.shortestPath() else {
            fatalError("no path found!")
        }

        return cost
    }

    public func fastestPathTwice() -> Int {
        let startLocation = space.startIndex.advanced(by: 1)
        let endLocation = space.endIndex.advanced(by: -2).coordinate.withoutTime()

        let startState = ValleySearchState(space: space,
                                           location: startLocation,
                                           remainingGoals: [endLocation, startLocation.coordinate.withoutTime(), endLocation])

        let search = AStarSearch(initial: startState, goal: .none)

        return search.shortestPath()?.cost ?? -1
    }
}

struct ValleySearchState {
    let space: Grid2DTime<Contents>
    let location: Grid2DTimeIndex

    // elf forgot his snacks, running A* with intermediate stops
    // by treating them as a sequence of goals
    let remainingGoals: [Coordinate2D]
}

extension ValleySearchState: SearchState {
    // tracking progress toward goal inside the SearchState
    typealias Goal = Optional<Never>

    func estimatedCost(toReach goals: Goal) -> Int {
        let paths = zip([location.coordinate.withoutTime()] + remainingGoals, remainingGoals)

        return paths.reduce(0) { (sum, path) in
            return sum + path.0.manhattanDistance(to: path.1)
        }
    }

    func adjacentStates() -> any Sequence<Step> {
        return space
            .neighbors(of: location)
            .lazy
            .filter { space[$0] == .empty }
            .map { location in
                guard let nextGoal = remainingGoals.first else {
                    fatalError("Finding adjacent states of a goal?")
                }
                if location.coordinate == nextGoal {
                    // neighbor is the next goal, remove it from remaining
                    return ValleySearchState(space: space,
                                             location: location,
                                             remainingGoals: Array(remainingGoals.dropFirst()))
                } else {
                    // neighbor is not the next goal, keep looking
                    return ValleySearchState(space: space,
                                             location: location,
                                             remainingGoals: remainingGoals)
                }
            }
            .map { (cost: 1, state: $0) }
    }

    func isGoal(_ goal: Goal) -> Bool {
        // hit all of the goals
        return self.remainingGoals.isEmpty
    }
}

// helper for valley construction, mapping (x,y,t) to snow T/F
struct Blizzard {
    // column to T/F there was an upward facing blizzard at t=0 for each row
    let up: [Int: [Bool]]
    let down: [Int: [Bool]]

    // row number to T/F there was a left-facing blizzard at t=0 for each column
    let left: [Int: [Bool]]
    let right: [Int: [Bool]]

    let xRange: Range<Int>
    let yRange: Range<Int>

    init(_ rows: some Sequence<some Sequence<Character>>) {
        var up = [Int: [Bool]]()
        var down = [Int: [Bool]]()
        var left = [Int: [Bool]]()
        var right = [Int: [Bool]]()

        var xMax = 0, yMax = 0

        for (rowNum, row) in rows.enumerated() {
            for (colNum, char) in row.enumerated() {
                up[colNum, default: []].append(char == "^")
                down[colNum, default: []].append(char == "v")
                left[rowNum, default: []].append(char == "<")
                right[rowNum, default: []].append(char == ">")

                xMax = max(xMax, colNum)
            }

            yMax = max(yMax, rowNum)
        }

        self.up = up
        self.down = down
        self.left = left
        self.right = right

        self.xRange = (0 ..< xMax + 1)
        self.yRange = (0 ..< yMax + 1)
    }

    public func isSnowing(x: Int, y: Int, t: Int) -> Bool {
        let upIndex = mod(y + t, yRange.count)
        let downIndex = mod(y - t, yRange.count)
        let leftIndex = mod(x + t, xRange.count)
        let rightIndex = mod(x - t, xRange.count)

        return (up[x]![upIndex] ||
                down[x]![downIndex] ||
                left[y]![leftIndex] ||
                right[y]![rightIndex])
    }
}


extension Contents: CustomStringConvertible {
    public var description: String {
        switch self {
        case .wall: return "#"
        case .empty: return "."
        case .blizzard: return "*"
        }
    }
}

/// https://stackoverflow.com/a/41180619
fileprivate func mod(_ a: Int, _ n: Int) -> Int {
    precondition(n > 0, "modulus must be positive")
    let r = a % n
    return r >= 0 ? r : r + n
}


extension ValleySearchState: Hashable {
    // just ignore immutable space for this search, since it'd be an error to compare two different search states

    func hash(into hasher: inout Hasher) {
        hasher.combine(location.coordinate)
        hasher.combine(remainingGoals)
    }

    static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.location == rhs.location && lhs.remainingGoals == rhs.remainingGoals
    }
}
