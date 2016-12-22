import Foundation

public enum Element: CustomStringConvertible {
    case lithium, hydrogen // example
    case strontium, plutonium, thulium, ruthenium, curium // my input
    case dilithium, elerium // part 2

    public var description: String {
        switch self {
        case .lithium: return "L"
        case .hydrogen: return "H"
        case .strontium: return "S"
        case .plutonium: return "P"
        case .thulium: return "T"
        case .ruthenium: return "R"
        case .curium: return "C"
        case .dilithium: return "D"
        case .elerium: return "E"
        }
    }
}

enum ObjectType: CustomStringConvertible {
    case chip, generator

    static var cases: [ObjectType] {
        return [ObjectType.chip, .generator]
    }

    var complement: ObjectType {
        switch self {
        case .chip: return .generator
        case .generator: return .chip
        }
    }

    var description: String {
        switch self {
        case .chip: return "M"
        case .generator: return "G"
        }
    }
}

struct SetsOfElements: CustomStringConvertible {
    var chips: Set<Element>
    var generators: Set<Element>

    init(chips: [Element] = [], generators: [Element] = []) {
        self.chips = Set(chips)
        self.generators = Set(generators)
    }

    subscript(_ type: ObjectType) -> Set<Element> {
        get {
            switch type {
            case .chip: return chips
            case .generator: return generators
            }
        }
        set(newValue) {
            switch type {
            case .chip: chips = newValue
            case .generator: generators = newValue
            }
        }
    }

    var description: String {
        return ObjectType.cases.flatMap { type in self[type].map { element in element.description + type.description } }.joined(separator: " ")
    }
}

typealias ElevatorPayload = SetsOfElements


public struct Floor {
    var unpaired = SetsOfElements()
    var paired: Set<Element> = []

    public init(chips: [Element] = [], generators: [Element] = []) {
        self.add(ElevatorPayload(chips: chips, generators: generators))
    }

    func isValid() -> Bool {
        // Only safe when either no unpaired chips, or no generators (paired or not)
        return unpaired.chips.count == 0 || (unpaired.generators.count == 0 && paired.count == 0)
    }

    mutating func add(_ payload: ElevatorPayload) {
        for type in ObjectType.cases {
            for element in payload[type] {
                if unpaired[type.complement].contains(element) {
                    unpaired[type.complement].remove(element)
                    paired.insert(element)
                } else {
                    unpaired[type].insert(element)
                }
            }
        }
    }

    mutating func remove(_ payload: ElevatorPayload) {
        for type in ObjectType.cases {
            for element in payload[type] {
                if unpaired[type].contains(element) {
                    unpaired[type].remove(element)
                } else if paired.contains(element) {
                    paired.remove(element)
                    unpaired[type.complement].insert(element)
                } else {
                    fatalError("Cannot remove \(element)-\(type) from this floor since it isn't on this floor")
                }
            }
        }
    }

    func adding(_ payload: ElevatorPayload) -> Floor {
        var floor = self

        floor.add(payload)

        return floor
    }

    func removing(_ payload: ElevatorPayload) -> Floor {
        var floor = self

        floor.remove(payload)

        return floor
    }

    func unpair() -> SetsOfElements {
        var sets = unpaired

        for element in paired {
            sets.chips.insert(element)
            sets.generators.insert(element)
        }

        return sets
    }
}

public struct Building: CustomStringConvertible {
    public var floors: [Floor]
    var elevatorLocation: Int = 0

    enum Direction {
        case Up, Down
    }

    public init(_ floors: [Floor]) {
        self.floors = floors
    }

    public var description: String {
        return floors.enumerated().reversed().map { (index, floor) -> String in
            let elevator = elevatorLocation == index ? "E" : "."
            return "F\(index + 1) \(elevator) \(floor.unpair().description)"
            }.joined(separator: "\n")
    }

    func moving(payload: ElevatorPayload, direction: Direction) -> Building? {
        if (elevatorLocation == 0 && direction == .Down) ||
            (elevatorLocation == floors.count - 1 && direction == .Up) {
            return nil
        }

        var result = self

        result.floors[result.elevatorLocation].remove(payload)
        guard result.floors[result.elevatorLocation].isValid() else {
            return nil
        }

        result.elevatorLocation += (direction == .Up ? 1 : -1)

        result.floors[result.elevatorLocation].add(payload)
        guard result.floors[result.elevatorLocation].isValid() else {
            return nil
        }

        return result
    }

    func goal() -> Building {
        var result = self

        let finalFloor = result.floors.count - 1
        result.elevatorLocation = finalFloor

        for (level, floor) in result.floors.dropLast().enumerated() {
            let floorContents = floor.unpair()
            result.floors[level].remove(floorContents)
            result.floors[finalFloor].add(floorContents)
        }
        
        return result
    }

    public func shortestPath() -> (cost: Int, steps: [Building])? {
        let search = AStarSearch(initial: self, goal: goal())

        return search.shortestPath()
    }
}

extension SetsOfElements: Hashable {
    static func ==(_ lhs: SetsOfElements, _ rhs: SetsOfElements) -> Bool {
        return lhs.chips == rhs.chips && lhs.generators == rhs.generators
    }

    var hashValue: Int {
        return self.chips.hashValue &* 31 &+ self.generators.hashValue
    }
}

extension Floor: Hashable {
    public static func ==(_ lhs: Floor, _ rhs: Floor) -> Bool {
        return lhs.unpaired == rhs.unpaired && lhs.paired == rhs.paired
    }

    public var hashValue: Int {
        return self.unpaired.hashValue &* 31 &+ self.paired.hashValue
    }
}

extension Building: Hashable {
    public static func ==(_ lhs: Building, _ rhs: Building) -> Bool {
        return lhs.elevatorLocation == rhs.elevatorLocation && lhs.floors == rhs.floors
    }

    public var hashValue: Int {
        return self.floors.reduce(self.elevatorLocation.hashValue) { $0 &* 31 &+ $1.hashValue }
    }
}

extension Building: SearchState {
    public func estimatedCost(toReach goal: Building) -> SearchState.Cost {
        typealias Reduce = (cost: Int, count: Int)
        return floors.dropLast().reduce((cost: 0, count: 0)) { (answer: Reduce, floor: Floor) -> Reduce in
            let count = answer.count + floor.paired.count * 2 + floor.unpaired.chips.count + floor.unpaired.generators.count

            return (cost: max(1, 2 * count - 3), count: count)
            }.cost
    }

    public func adjacentStates() -> AnySequence<(cost: SearchState.Cost, state: Building)> {
        let unpaired = self.floors[self.elevatorLocation].unpair()

        let allChips = AnyCollection(unpaired.chips)
        let allGenerators = AnyCollection(unpaired.generators)
        let twoChips = allChips.combinations(takenBy: 2)
        let oneChip = allChips.combinations(takenBy: 1)
        let twoGenerators = allGenerators.combinations(takenBy: 2)
        let oneGenerator = allGenerators.combinations(takenBy: 1)

        let chips = [oneChip, twoChips].flatMap { $0.map { SetsOfElements(chips: $0) } }
        let generators = [oneGenerator, twoGenerators].flatMap { $0.map { SetsOfElements(generators: $0) } }
        let mixed = oneChip.flatMap { chips in oneGenerator.map { generators in SetsOfElements(chips: chips, generators: generators) }}

        let allPayloads = [chips, generators, mixed].flatMap { $0 }

        return AnySequence([Direction.Up, .Down].flatMap { direction in
            allPayloads.flatMap { payload in
                self.moving(payload: payload, direction: direction)
            }
            }.map { building in
                (cost: 1, state: building)
        })
    }
}
