import Foundation

public class ConwayHyperCube: CustomStringConvertible {
    var grid: Grid4D<State>

    public init(_ string: String) {
        let initialPlane = string.lines().map { line in
            line.compactMap(State.init)
        }

        grid = Grid4D([[initialPlane]])
    }

    public var description: String {
        return String(describing: grid)
    }

    public func step() {
        let originalGrid = grid

        let xRange = grid.xRange.expand(lower: 1, upper: 1)
        let yRange = grid.yRange.expand(lower: 1, upper: 1)
        let zRange = grid.zRange.expand(lower: 1, upper: 1)
        var wRange = grid.wRange.expand(lower: 1, upper: 1)

        var newState = wRange.map { w in
            zRange.map { z in
                yRange.map { y in
                    xRange.map { x -> State in
                        let coord = Coordinate4D(x: x, y: y, z: z, w: w)
                        let previousState = originalGrid[coord] ?? .inactive
                        let activeNeighborCount = coord.neighbors().reduce(0) { sum, neighbor in
                            sum + (originalGrid[neighbor] == .some(.active) ? 1 : 0)
                        }

                        if (previousState == .active && (2...3).contains(activeNeighborCount))
                            || (previousState == .inactive && 3 == activeNeighborCount) {
                            return .active
                        } else {
                            return .inactive
                        }
                    }
                }
            }
        }

        // so tempted to trim the ranges if we didn't need to expand them, but then I'd have to
        // trim the arrays too... At least W is easy-ish
        var changed: Bool
        repeat {
            changed = false
            if let firstW = newState.first,
               firstW.allSatisfy({ eachPlane in eachPlane.allSatisfy({ eachRow in eachRow.allSatisfy { element in element == .inactive }})}) {
                newState.removeFirst()
                wRange = wRange.contract(lower: 1)
                changed = true
            }
        } while (changed)

        repeat {
            changed = false
            if let lastW = newState.last,
               lastW.allSatisfy({ eachPlane in eachPlane.allSatisfy({ eachRow in eachRow.allSatisfy { element in element == .inactive }})}) {
                newState.removeLast()
                wRange = wRange.contract(upper: 1)
                changed = true
            }
        } while (changed)


        grid = Grid4D(newState,
                      xStart: xRange.lowerBound,
                      yStart: yRange.lowerBound,
                      zStart: zRange.lowerBound,
                      wStart: wRange.lowerBound)
    }

    public func activeCount() -> Int {
        return grid.reduce(0) { sum, element in
            sum + (element == .active ? 1 : 0)
        }
    }
}
