import Foundation

enum GridSquare: CustomStringConvertible, Equatable {
    case start
    case end
    case elevation(Character)

    init(_ c: Character) {
        switch c {
        case "S": self = .start
        case "E": self = .end
        case "a"..."z": self = .elevation(c)
        default: fatalError("invalid grid square character: \(c)")
        }
    }

    var description: String {
        switch self {
        case .start:
            return "S"
        case .end:
            return "E"
        case .elevation(let character):
            return String(character)
        }
    }

    var heightValue: Int {
        let heightValue = switch self {
        case .start:
            Character("a")
        case .end:
            Character("z")
        case .elevation(let character):
            character
        }

        return Int(heightValue.asciiValue!)
    }
}

public struct Heightmap {
    let heightGrid: Grid<GridSquare>
    public let location: GridIndex

    public init(_ input: String) {
        let squares = input.lines().map { line in
            line.map(GridSquare.init)
        }

        heightGrid = Grid(squares, connectivity: .fourWay)
        location = heightGrid.firstIndex { .start == $0 }!
    }

    init(heightGrid: Grid<GridSquare>, location: GridIndex) {
        self.heightGrid = heightGrid
        self.location = location
    }

    var start: GridIndex {
        heightGrid.firstIndex { .start == $0 }!
    }

    var goal: GridIndex {
        heightGrid.firstIndex { .end == $0 }!
    }
}

extension Heightmap: Hashable {
    // assumes never comparing from different maps

    public static func ==(_ lhs: Heightmap, _ rhs: Heightmap) -> Bool {
        return lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }
}

extension Heightmap: SearchState {
    public func goalState() -> Heightmap {
        return Heightmap(heightGrid: heightGrid, location: goal)
    }

    public func estimatedCost(toReach goal: Heightmap) -> Cost {
        // yup, just an estimate
        return location.manhattanDistance(to: goal.location)
    }

    public func adjacentStates() -> any Sequence<Step> {
        return heightGrid.neighbors(of: location)
            .filter { destinationLocation in
                // "elevation of the destination square can be at most one higher than the elevation of your current square"
                heightGrid[location].heightValue + 1 >= heightGrid[destinationLocation].heightValue
            }
            .map { neighborLocation in
                (cost: 1,
                 state: Heightmap(heightGrid: heightGrid,
                                  location: neighborLocation))
            }
    }
}

extension Heightmap: DijkstraGraph {
    public func allVertices() -> any Sequence<GridIndex> {
        return heightGrid.indices
    }

    public func neighbors(of location: GridIndex) -> any Sequence<(Int, GridIndex)> {
        return heightGrid.neighbors(of: location)
            .filter { startingLocation in
                // "elevation of the destination square can be at most one higher than the elevation of your current square"
                // ensure elevation isn't too low. For djikstra, search descends
                heightGrid[startingLocation].heightValue + 1 >= heightGrid[location].heightValue
            }
            .map {
                (1, $0)
            }
    }

    public func part2() -> Int? {
        let dijkstra = Dijkstra(graph: self, initialVertex: goal)

        return heightGrid
            .indices
            .filter { idx in
                // find all squares with same height as start square
                heightGrid[idx].heightValue == GridSquare.start.heightValue
            }.map { idx in
                // convert them to their costs
                dijkstra.cost[idx]!
            }
            .min() // and find the shortest
    }
}

