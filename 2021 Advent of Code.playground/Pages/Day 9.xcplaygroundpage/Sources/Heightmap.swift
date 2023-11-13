import Foundation

public struct HeightMap {
    let grid: Grid<Int>

    public init(_ string: String) {
        let heights = string.lines()
            .map() { line in
                line.compactMap { char in
                    Int(String(char))
                }
            }

        self.grid = Grid(heights, connectivity: GridConnectivity.fourWay)
    }

    public func part1() -> Int {
        return lowPoints()
            .map { idx in
                // risk value
                grid[idx] + 1
            }
            .reduce(0, +)
    }

    public func lowPoints() -> some Collection<GridIndex> {
        return grid.indices
            .filter { idx in
                grid.neighbors(of: idx).allSatisfy { neighbor in
                    grid[idx] < grid[neighbor]
                }
            }
    }
}

extension HeightMap {
    public func basins() -> [Int] {
        return lowPoints().map { startIdx in
            var closedSet: Set<GridIndex> = [startIdx]
            var openList = [startIdx]

            while let next = openList.popLast() {
                // Problem definition says all basins
                // surrounded by ridge height 9
                let basinNeighbors = grid.neighbors(of: next)
                    .filter { grid[$0] < 9 }

                let newNeighbors = Set(basinNeighbors).subtracting(closedSet)

                openList.append(contentsOf: newNeighbors)
                closedSet.formUnion(newNeighbors)
            }

            return closedSet.count
        }
    }

    public func part2() -> Int {
        return basins().max(count: 3).reduce(1, *)
    }
}
