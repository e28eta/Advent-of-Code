import Foundation
import RegexBuilder

enum Material: CaseIterable {
    case ore, clay, obsidian, geode
}

struct Robot {
    let collects: Material
    let costs: [Material: Int]
}

public struct Blueprint {
    public let number: Int
    let robots: [Material: Robot]
    // upper bound on # robots of each material to build,
    // based on most expensive cost for that material
    let maxRobotsToBuild: [Material: Int]

    public func geodeCount(after rounds: Int) -> Int {
        return bestGeodeCount(FactoryState(
            materialInventory: [:],
            robotInventory: [.ore: 1],
            roundsLeft: rounds,
            ignoredRobotTypes: []))
    }

    func bestGeodeCount(_ state: FactoryState) -> Int {
        var state = state

        // figure out possible robots before collecting
        let possibleRobots = constructableRobots(state.materialInventory)
        let newlyPossibleRobots = possibleRobots.subtracting(state.ignoredRobotTypes)
        let anyUnaffordableRobots = possibleRobots.count != Material.allCases.count

        state.collectMaterialForRound()

        var bestScore = state.materialInventory[.geode, default: 0]

        if state.roundsLeft > 0 {
            if newlyPossibleRobots.isEmpty {
                // still saving up to build something
                assert(anyUnaffordableRobots, "there are no unaffordable robots, should have built something previously! \(possibleRobots); \(newlyPossibleRobots), \(state.ignoredRobotTypes)")
                if state.hypotheticalBestScore() > bestScore {
                    bestScore = max(bestScore, bestGeodeCount(state))
                }
            } else {
                // try saving up for the unaffordable robots first, which are
                // more likely to be score-producing
                if anyUnaffordableRobots {
                    // TODO: I wonder if this is a problem due to branches that'll never produce
                    let nextState = state.ignoring(possibleRobots)
                    // check heuristic
                    if nextState.hypotheticalBestScore() > bestScore {
                        // heuristic didn't disqualify this branch, calculate actual
                        bestScore = max(bestScore, bestGeodeCount(nextState))
                    }
                }

                // try building each of the newly possible robots
                for robotType in newlyPossibleRobots where !state.satisfiedRobots.contains(robotType) {
                    let nextState = state.building(robots[robotType]!,
                                                   max: maxRobotsToBuild[robotType, default: .max])
                    // check heuristic
                    if nextState.hypotheticalBestScore() > bestScore {
                        // heuristic didn't disqualify this branch, calculate actual
                        bestScore = max(bestScore, bestGeodeCount(nextState))
                    }
                }
            }
        }

        return bestScore
    }

    func constructableRobots(_ inventory: [Material: Int]) -> Set<Material> {
        return robots.filter { (_, robot) in
            robot.costs.allSatisfy { (material, cost) in
                inventory[material, default: 0] >= cost
            }
        }
        .reduce(into: Set()) {
            $0.insert($1.0)
        }
    }
}

struct FactoryState {
    // How much of each material has been collected so far
    var materialInventory: [Material: Int]
    // How many of each robot has been built
    var robotInventory: [Material: Int]
    // How many more rounds to simulate
    var roundsLeft: Int
    // last time we chose to wait instead of building a robot,
    // which robot choices were available?
    var ignoredRobotTypes: Set<Material>
    // robots who I have more than enough
    var satisfiedRobots: Set<Material> = []

    mutating func collectMaterialForRound() {
        assert(roundsLeft >= 0, "should not collect material if no rounds left")

        roundsLeft -= 1
        for (material, count) in robotInventory {
            materialInventory[material, default: 0] += count
        }
    }

    func building(_ robot: Robot, max maxNeeded: Int) -> FactoryState {
        var newState = self

        newState.robotInventory[robot.collects, default: 0] += 1
        for (material, cost) in robot.costs {
            newState.materialInventory[material]! -= cost
        }

        if newState.robotInventory[robot.collects]! >= maxNeeded {
            newState.satisfiedRobots.insert(robot.collects)
        }

        newState.ignoredRobotTypes = []

        return newState
    }

    func ignoring(_ robotTypes: Set<Material>) -> FactoryState {
        var newState = self

        newState.ignoredRobotTypes = robotTypes

        return newState
    }

    func hypotheticalBestScore() -> Int {
        // branch pruning heuristic

        // current score
        return (materialInventory[.geode, default: 0]
                // existing robots deliver a geode every round
                + robotInventory[.geode, default: 0] * roundsLeft
                // one new geode-producing robot for every round remaining
                + roundsLeft * (roundsLeft + 1) / 2)
    }
}


let EnglishLocale = Locale(identifier: "en-US")
extension Blueprint {
    static let BlueprintNumberRef = Reference<Int>()

    static let OreRobotCost = Reference<Int>()
    static let ClayRobotCost = Reference<Int>()
    static let ObsidianRobotOreCost = Reference<Int>()
    static let ObsidianRobotClayCost = Reference<Int>()
    static let GeodeRobotOreCost = Reference<Int>()
    static let GeodeRobotObsidianCost = Reference<Int>()

    static let MatchingRegex = Regex {
        Anchor.startOfLine
        "Blueprint "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: BlueprintNumberRef)
        ": Each ore robot costs "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: OreRobotCost)
        " ore. Each clay robot costs "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: ClayRobotCost)
        " ore. Each obsidian robot costs "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: ObsidianRobotOreCost)
        " ore and "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: ObsidianRobotClayCost)
        " clay. Each geode robot costs "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: GeodeRobotOreCost)
        " ore and "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: GeodeRobotObsidianCost)
        " obsidian."
        Anchor.endOfLine
    }

    public init?(_ string: String) {
        guard let match = try? Blueprint.MatchingRegex.firstMatch(in: string) else {
            return nil
        }

        self.number = match[Blueprint.BlueprintNumberRef]

        let robots = [
            Material.ore: Robot(collects: .ore, costs: [
                .ore: match[Blueprint.OreRobotCost],
            ]),
            .clay: Robot(collects: .clay, costs: [
                .ore: match[Blueprint.ClayRobotCost],
            ]),
            .obsidian: Robot(collects: .obsidian, costs: [
                .ore: match[Blueprint.ObsidianRobotOreCost],
                .clay: match[Blueprint.ObsidianRobotClayCost],
            ]),
            .geode: Robot(collects: .geode, costs: [
                .ore: match[Blueprint.GeodeRobotOreCost],
                .obsidian: match[Blueprint.GeodeRobotObsidianCost],
            ]),
        ]

        self.robots = robots
        // factory limited to building one robot per round, never need more
        // robots than the most expensive cost of that material
        self.maxRobotsToBuild = robots.values.reduce(into: [:]) { dict, robot in

            for (material, cost) in robot.costs {
                dict[material] = max(cost, dict[material, default: 0])
            }

        }
    }
}
