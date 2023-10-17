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

//extension GridSquare: Strideable {
//    typealias Stride = Int
//
//    func distance(to other: GridSquare) -> Int {
//        heightValue.distance(to: other.heightValue)
//    }
//
//    func advanced(by n: Int) -> GridSquare {
//        return .elevation(Character(UnicodeScalar(heightValue + n)!))
//    }
//}

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
        hasher.combine(location.row)
        hasher.combine(location.col)
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

    public func adjacentStates() -> AnySequence<Step> {
        let adjacentStates = heightGrid.neighbors(of: location)
            .filter { neighborLocation in
                // ensure elevation isn't too high
                heightGrid[location].heightValue + 1 >= heightGrid[neighborLocation].heightValue
            }
            .map { neighborLocation in
                (cost: 1,
                 state: Heightmap(heightGrid: heightGrid,
                                  location: neighborLocation))
            }

        return AnySequence(adjacentStates)
    }
}
