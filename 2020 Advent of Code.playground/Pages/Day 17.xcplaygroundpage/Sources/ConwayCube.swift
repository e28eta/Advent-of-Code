import Foundation

public enum State: Character, CustomStringConvertible {
    case inactive = "."
    case active = "#"

    public var description: String {
        return String(rawValue)
    }
}

public class ConwayCube: CustomStringConvertible {
    var grid: Grid3D<State>

    public init(_ string: String) {
        let initialPlane = string.lines().map { line in
            line.compactMap(State.init)
        }

        grid = Grid3D([initialPlane])
    }

    public var description: String {
        return String(describing: grid)
    }

    public func step() {
        let originalGrid = grid

        let xRange = grid.xRange.expand(lower: 1, upper: 1)
        let yRange = grid.yRange.expand(lower: 1, upper: 1)
        var zRange = grid.zRange.expand(lower: 1, upper: 1)

        var newState = zRange.map { z in
            yRange.map { y in
                xRange.map { x -> State in
                    let coord = Coordinate3D(x: x, y: y, z: z)
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

        // so tempted to trim the ranges if we didn't need to expand them, but then I'd have to
        // trim the arrays too... At least Z is easy-ish
        var changed: Bool
        repeat {
            changed = false
            if let firstZ = newState.first,
               firstZ.allSatisfy({ eachRow in eachRow.allSatisfy { element in element == .inactive }}) {
                newState.removeFirst()
                zRange = zRange.contract(lower: 1)
                changed = true
            }
        } while (changed)
        
        repeat {
            changed = false
            if let lastZ = newState.last,
               lastZ.allSatisfy({ eachRow in eachRow.allSatisfy { element in element == .inactive }}) {
                newState.removeLast()
                zRange = zRange.contract(upper: 1)
                changed = true
            }
        } while (changed)


        grid = Grid3D(newState,
                      xStart: xRange.lowerBound,
                      yStart: yRange.lowerBound,
                      zStart: zRange.lowerBound)
    }

    public func activeCount() -> Int {
        return grid.reduce(0) { sum, element in
            sum + (element == .active ? 1 : 0)
        }
    }
}
