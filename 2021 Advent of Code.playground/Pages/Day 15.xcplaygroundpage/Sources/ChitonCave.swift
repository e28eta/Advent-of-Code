import Foundation

// class to make the reference to the grid cheap?

public class ChitonCave {
    let grid: Grid<Int>

    public init(_ string: String) {
        let risks = string.lines().map {
            $0.compactMap { c in Int(String(c)) }
        }

        grid = Grid(risks, connectivity: GridConnectivity.fourWay)
    }

    public func leastRiskyPath() -> Int {
        let start = CaveSearchState(cave: self, location: grid.startIndex)
        let end = CaveSearchState(cave: self, location: grid.index(before: grid.endIndex))

        let aStar = AStarSearch(initial: start,
                                goal: end)

        return aStar.shortestPath()!.cost
    }
}

struct CaveSearchState: Hashable {
    let cave: ChitonCave
    let location: GridIndex

    // assumes never comparing from different maps
    public static func ==(_ lhs: CaveSearchState, _ rhs: CaveSearchState) -> Bool {
        return lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }
}

extension CaveSearchState: SearchState {
    typealias Goal = Self

    func estimatedCost(toReach goal: Goal) -> Int {
        // if every square between was risk 1
        return location.manhattanDistance(to: goal.location)
    }

    func adjacentStates() -> any Sequence<(cost: Int, state: Self)> {
        return cave.grid.neighbors(of: location).map { idx in
            // cost to enter idx is the value stored there
            return (cost: cave.grid[idx],
                    state: CaveSearchState(cave: cave, location: idx))
        }
    }
}
