import Foundation

enum Location: CustomStringConvertible {
    case wall, open, exposedWire(Character)

    init(_ string: Character) {
        switch string {
        case "#": self = .wall
        case ".": self = .open
        default: self = .exposedWire(string)
        }
    }

    var description: String {
        switch self {
        case .wall: return "#"
        case .open: return "."
        case .exposedWire(let c): return c.description
        }
    }
}

struct AirDuctLocation: SearchState {
    let coordinate: Coordinate
    let airDuct: AirDuct

    func estimatedCost(toReach goal: AirDuctLocation) -> SearchState.Cost {
        return self.coordinate.distance(to: goal.coordinate)
    }

    func adjacentStates() -> AnySequence<(cost: SearchState.Cost, state: AirDuctLocation)> {
        return AnySequence([(-1, 0), (1, 0), (0, -1), (0, 1)].map { coordinate + $0 }.filter {
            switch airDuct[$0] {
            case .open, .exposedWire(_): return true
            case .wall: return false
            }
            }.map { (cost: 1, state: AirDuctLocation(coordinate: $0, airDuct: airDuct)) })
    }

    static func ==(_ lhs: AirDuctLocation, _ rhs: AirDuctLocation) -> Bool {
        return lhs.coordinate == rhs.coordinate
    }

    var hashValue: Int {
        return self.coordinate.hashValue
    }
}

public class AirDuct: CustomStringConvertible {
    let locations: [Coordinate: Location]
    let xRange: CountableRange<Int>, yRange: CountableRange<Int>

    public let wires: [Coordinate]

    public lazy var startLocation: Coordinate = {
        self.locations.first { if case .exposedWire("0") = $0.value { return true } else { return false } }!.key
    }()

    public lazy var shortestPathLengths: [Coordinate: [Coordinate: Int]] = {
        var result: [Coordinate : [Coordinate : Int]] = [:]

        let updateResult = { (first: Coordinate, second: Coordinate, amount: Int) in
            if result[first] == nil {
                result[first] = [second: amount]
            } else {
                result[first]![second] = amount
            }
        }

        for (idx, firstWire) in self.wires.enumerated() {
            for secondWire in self.wires.suffix(from: self.wires.index(after: idx)) {
                let search = AStarSearch(initial: AirDuctLocation(coordinate: firstWire, airDuct: self), goal: AirDuctLocation(coordinate: secondWire, airDuct: self))
                guard let path = search.shortestPath() else { fatalError("cannot find path between \(firstWire) and \(secondWire)") }

                updateResult(firstWire, secondWire, path.cost)
                updateResult(secondWire, firstWire, path.cost)
            }
        }

        return result
    }()


    public init(_ string: String) {
        var dictionary: [Coordinate: Location] = [:]

        let lines = string.components(separatedBy: .newlines)

        yRange = (0..<lines.endIndex)
        let numCharacters = lines.first!.characters.count
        xRange = (0..<numCharacters)

        for (y, line) in lines.enumerated() {
            assert(numCharacters == line.characters.count, "Every line must have the same number of locations")

            for (x, char) in line.characters.enumerated() {
                dictionary[Coordinate(x: x, y: y)] = Location(char)
            }
        }

        locations = dictionary

        wires = locations.filter { if case .exposedWire(_) = $0.value { return true } else { return false } }.map { $0.key }

    }

    subscript(_ coords: (Int, Int)) -> Location {
        return self[Coordinate(x: coords.0, y: coords.1)]
    }

    subscript(_ coords: Coordinate) -> Location {
        assert(xRange.contains(coords.x))
        assert(yRange.contains(coords.y))

        return locations[coords]!
    }

    public var description: String {
        return yRange.map { y in
            xRange.reduce("") { (str, x) in
                str + self[(x, y)].description
            }
            }.joined(separator: "\n")
    }
}
