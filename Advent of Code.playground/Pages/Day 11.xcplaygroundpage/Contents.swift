//: [Previous](@previous)

/*:
 # Day 11: Radioisotope Thermoelectric Generators

 You come upon a column of four floors that have been entirely sealed off from the rest of the building except for a small dedicated lobby. There are some radiation warnings and a big sign which reads "Radioisotope Testing Facility".

 According to the project status board, this facility is currently being used to experiment with [Radioisotope Thermoelectric Generators](https://en.wikipedia.org/wiki/Radioisotope_thermoelectric_generator) (RTGs, or simply "generators") that are designed to be paired with specially-constructed microchips. Basically, an RTG is a highly radioactive rock that generates electricity through heat.

 The experimental RTGs have poor radiation containment, so they're dangerously radioactive. The chips are prototypes and don't have normal radiation shielding, but they do have the ability to **generate an electromagnetic radiation shield when powered.** Unfortunately, they can **only** be powered by their corresponding RTG. An RTG powering a microchip is still dangerous to other microchips.

 In other words, if a chip is ever left in the same area as another RTG, and it's not connected to its own RTG, the chip will be **fried**. Therefore, it is assumed that you will follow procedure and keep chips connected to their corresponding RTG when they're in the same room, and away from other RTGs otherwise.

 These microchips sound very interesting and useful to your current activities, and you'd like to try to retrieve them. The fourth floor of the facility has an assembling machine which can make a self-contained, shielded computer for you to take with you - that is, if you can bring it all of the RTGs and microchips.

 Within the radiation-shielded part of the facility (in which it's safe to have these pre-assembly RTGs), there is an elevator that can move between the four floors. Its capacity rating means it can carry at most yourself and two RTGs or microchips in any combination. (They're rigged to some heavy diagnostic equipment - the assembling machine will detach it for you.) As a security measure, the elevator will only function if it contains at least one RTG or microchip. The elevator always stops on each floor to recharge, and this takes long enough that the items within it and the items on that floor can irradiate each other. (You can prevent this if a Microchip and its Generator end up on the same floor in this way, as they can be connected while the elevator is recharging.)

 You make some notes of the locations of each component of interest (your puzzle input). Before you don a hazmat suit and start moving things around, you'd like to have an idea of what you need to do.

 When you enter the containment area, you and the elevator will start on the first floor.

 For example, suppose the isolated area has the following arrangement:

 ````
 The first floor contains a hydrogen-compatible microchip and a lithium-compatible microchip.
 The second floor contains a hydrogen generator.
 The third floor contains a lithium generator.
 The fourth floor contains nothing relevant.
 ````
 As a diagram (`F#` for a Floor number, `E` for Elevator, `H` for Hydrogen, `L` for Lithium, `M` for Microchip, and `G` for Generator), the initial state looks like this:

 ````
 F4 .  .  .  .  .
 F3 .  .  .  LG .
 F2 .  HG .  .  .
 F1 E  .  HM .  LM
 ````

 Then, to get everything up to the assembling machine on the fourth floor, the following steps could be taken:

 Bring the Hydrogen-compatible Microchip to the second floor, which is safe because it can get power from the Hydrogen Generator:
 ````
 F4 .  .  .  .  .
 F3 .  .  .  LG .
 F2 E  HG HM .  .
 F1 .  .  .  .  LM
 ````

 Bring both Hydrogen-related items to the third floor, which is safe because the Hydrogen-compatible microchip is getting power from its generator:
 ````
 F4 .  .  .  .  .
 F3 E  HG HM LG .
 F2 .  .  .  .  .
 F1 .  .  .  .  LM
 ````

 Leave the Hydrogen Generator on floor three, but bring the Hydrogen-compatible Microchip back down with you so you can still use the elevator:
 ````
 F4 .  .  .  .  .
 F3 .  HG .  LG .
 F2 E  .  HM .  .
 F1 .  .  .  .  LM
 ````

 At the first floor, grab the Lithium-compatible Microchip, which is safe because Microchips don't affect each other:
 ````
 F4 .  .  .  .  .
 F3 .  HG .  LG .
 F2 .  .  .  .  .
 F1 E  .  HM .  LM
 ````

 Bring both Microchips up one floor, where there is nothing to fry them:
 ````
 F4 .  .  .  .  .
 F3 .  HG .  LG .
 F2 E  .  HM .  LM
 F1 .  .  .  .  .
 ````

 Bring both Microchips up again to floor three, where they can be temporarily connected to their corresponding generators while the elevator recharges, preventing either of them from being fried:
 ````
 F4 .  .  .  .  .
 F3 E  HG HM LG LM
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 Bring both Microchips to the fourth floor:
 ````
 F4 E  .  HM .  LM
 F3 .  HG .  LG .
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 Leave the Lithium-compatible microchip on the fourth floor, but bring the Hydrogen-compatible one so you can still use the elevator; this is safe because although the Lithium Generator is on the destination floor, you can connect Hydrogen-compatible microchip to the Hydrogen Generator there:
 ````
 F4 .  .  .  .  LM
 F3 E  HG HM LG .
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 Bring both Generators up to the fourth floor, which is safe because you can connect the Lithium-compatible Microchip to the Lithium Generator upon arrival:
 ````
 F4 E  HG .  LG LM
 F3 .  .  HM .  .
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 Bring the Lithium Microchip with you to the third floor so you can use the elevator:
 ````
 F4 .  HG .  LG .
 F3 E  .  HM .  LM
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 Bring both Microchips to the fourth floor:
 ````
 F4 E  HG HM LG LM
 F3 .  .  .  .  .
 F2 .  .  .  .  .
 F1 .  .  .  .  .
 ````

 In this arrangement, it takes `11` steps to collect all of the objects at the fourth floor for assembly. (Each elevator stop counts as one step, even if nothing is added to or removed from it.)

 In your situation, what is the **minimum number of steps** required to bring all of the objects to the fourth floor?
 */

import Foundation

enum Element: CustomStringConvertible {
    case lithium, hydrogen // example
    case strontium, plutonium, thulium, ruthenium, curium // my input

    var description: String {
        switch self {
        case .lithium: return "L"
        case .hydrogen: return "H"
        case .strontium: return "S"
        case .plutonium: return "P"
        case .thulium: return "T"
        case .ruthenium: return "R"
        case .curium: return "C"
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

struct Floor {
    var unpaired = SetsOfElements()
    var paired: Set<Element> = []

    init(chips: [Element] = [], generators: [Element] = []) {
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

struct Building: CustomStringConvertible {
    var floors: [Floor]
    var elevatorLocation: Int = 0

    enum Direction {
        case Up, Down
    }

    init(_ floors: [Floor]) {
        self.floors = floors
    }

    var description: String {
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
    static func ==(_ lhs: Floor, _ rhs: Floor) -> Bool {
        return lhs.unpaired == rhs.unpaired && lhs.paired == rhs.paired
    }

    var hashValue: Int {
        return self.unpaired.hashValue &* 31 &+ self.paired.hashValue
    }
}

extension Building: Hashable {
    static func ==(_ lhs: Building, _ rhs: Building) -> Bool {
        return lhs.elevatorLocation == rhs.elevatorLocation && lhs.floors == rhs.floors
    }

    var hashValue: Int {
        return self.floors.reduce(self.elevatorLocation.hashValue) { $0 &* 31 &+ $1.hashValue }
    }
}

extension Building: SearchState {
    func estimatedCost(toReach goal: Building) -> SearchState.Cost {
        typealias Reduce = (cost: Int, count: Int)
        return floors.dropLast().reduce((cost: 0, count: 0)) { (answer: Reduce, floor: Floor) -> Reduce in
            let count = answer.count + floor.paired.count * 2 + floor.unpaired.chips.count + floor.unpaired.generators.count

            return (cost: max(1, 2 * count - 3), count: count)
            }.cost
    }

    func adjacentStates() -> AnySequence<(cost: SearchState.Cost, state: Building)> {
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


/*
 ````
 F4 .  .  .  .  .
 F3 .  .  .  LG .
 F2 .  HG .  .  .
 F1 E  .  HM .  LM
 ````
 */
let b = Building([Floor(chips: [.hydrogen, .lithium]),
                  Floor(generators: [.hydrogen]),
                  Floor(generators: [.lithium]),
                  Floor()])
let path = AStarSearch(initial: b, goal: b.goal()).shortestPath()

if let path = path {
    print("found solution!")
    print(path.cost)
    for step in path.steps {
        print(step)
    }
}

/*:
 # My Input:

 The first floor contains a strontium generator, a strontium-compatible microchip, a plutonium generator, and a plutonium-compatible microchip.
 The second floor contains a thulium generator, a ruthenium generator, a ruthenium-compatible microchip, a curium generator, and a curium-compatible microchip.
 The third floor contains a thulium-compatible microchip.
 The fourth floor contains nothing relevant.
 
 */

var str = "Hello, playground"

//: [Next](@next)
