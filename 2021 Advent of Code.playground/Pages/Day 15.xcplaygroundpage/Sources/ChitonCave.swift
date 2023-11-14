import Foundation

// class to make the reference to the grid cheap?

public struct ChitonCave {
    let grid: Grid<Int>
    let expandedGrid: Grid<Int>

    public init(_ string: String) {
        let risks = string.lines().map {
            $0.compactMap { c in Int(String(c)) }
        }

        grid = Grid(risks, connectivity: GridConnectivity.fourWay)

        let gridHeight = grid.height
        let gridWidth = grid.width

        let newHeight = gridHeight * 5
        let newWidth = gridWidth * 5

        let expandedRisks: [[Int]] = (0 ..< newHeight).map { row in
            let (rq, rr) = row.quotientAndRemainder(dividingBy: gridHeight)

            return (0 ..< newWidth).map { col in
                let (cq, cr) = col.quotientAndRemainder(dividingBy: gridWidth)

                // increases by one for each repeated row/col, but range is [1,9]
                return ((risks[rr][cr] + (rq + cq) - 1) % 9) + 1
            }
        }

        expandedGrid = Grid(expandedRisks,
                            connectivity: GridConnectivity.fourWay)
    }

    public func leastRiskyPath(expanded: Bool = false) -> Int {
        let gridToSearch = expanded ? expandedGrid : grid

        let start = CaveSearchState(grid: gridToSearch,
                                    location: gridToSearch.startIndex)
        let end = CaveSearchState(grid: gridToSearch,
                                  location: gridToSearch.index(before: gridToSearch.endIndex))

        let aStar = AStarSearch(initial: start, goal: end)

        return aStar.shortestPath()!.cost
    }
}

final class CaveSearchState: Hashable {
    let grid: Grid<Int>
    let location: GridIndex

    init(grid: Grid<Int>, location: GridIndex) {
        self.grid = grid
        self.location = location
    }

    // assumes never comparing from different maps
    public static func ==(_ lhs: CaveSearchState, _ rhs: CaveSearchState) -> Bool {
        return lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }
}

extension CaveSearchState: SearchState {
    func estimatedCost(toReach goal: CaveSearchState) -> Int {
        // if every square between was risk 1
        return location.manhattanDistance(to: goal.location)
    }

    func adjacentStates() -> any Sequence<(cost: Int, state: CaveSearchState)> {
        return grid.neighbors(of: location).map { idx in
            // cost to enter idx is the value stored there
            return (cost: grid[idx],
                    state: CaveSearchState(grid: grid, location: idx))
        }
    }
}

extension CaveSearchState: CustomStringConvertible {
    var description: String {
        return location.debugDescription
    }
}
