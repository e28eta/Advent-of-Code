import Foundation
import RegexBuilder

enum Material: String, CaseIterable {
    case ore, clay, obsidian, geode
}

struct Robot {
    let collects: Material
    let costs: [Material: Int]
}

public struct Blueprint {
    let number: Int
    let robots: [Material: Robot]
    // upper bound on # robots of each material to build,
    // based on most expensive cost for that material
    let maxRobotsToBuild: [Material: Int]

    public func qualityScore(after rounds: Int) -> Int {
        return bestQualityScore(FactoryState(
            maximumRobotsNeeded: maxRobotsToBuild,
            materialInventory: [:],
            robotInventory: [.ore: 1],
            roundsLeft: rounds,
            ignoredRobotTypes: []))
    }

    func bestQualityScore(_ state: FactoryState) -> Int {
        var state = state

        // figure out possible robots before collecting
        let possibleRobots = constructableRobots(state.materialInventory)
        let newlyPossibleRobots = possibleRobots.subtracting(state.ignoredRobotTypes)
        let anyUnaffordableRobots = possibleRobots.count != Material.allCases.count

        state.collectMaterialForRound()

        var bestScore = state.materialInventory[.geode, default: 0] * number

        // this might be off-by-one
        if state.roundsLeft > 0 {
            if newlyPossibleRobots.isEmpty {
                // still saving up to build something
                assert(anyUnaffordableRobots, "there are no unaffordable robots, should have built something previously!")
                bestScore = max(bestScore, bestQualityScore(state))
            } else {
                // try building each of the newly possible robots
                for robotType in newlyPossibleRobots {
                    let nextState = state.building(robots[robotType]!)
                    bestScore = max(bestScore, bestQualityScore(nextState))
                }

                // also try saving up for the unaffordable robots
                if anyUnaffordableRobots {
                    let nextState = state.ignoring(possibleRobots)
                    bestScore = max(bestScore, bestQualityScore(nextState))
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
    let maximumRobotsNeeded: [Material: Int]
    // How much of each material has been collected so far
    var materialInventory: [Material: Int]
    // How many of each robot has been built
    var robotInventory: [Material: Int]
    // How many more rounds to simulate
    var roundsLeft: Int
    // last time we chose to wait instead of building a robot,
    // which robot choices were available?
    var ignoredRobotTypes: Set<Material>

    mutating func collectMaterialForRound() {
        assert(roundsLeft >= 0, "should not collect material if no rounds left")

        roundsLeft -= 1
        for (material, count) in robotInventory {
            materialInventory[material, default: 0] += count
        }
    }

    func building(_ robot: Robot) -> FactoryState {
        var newState = self

        newState.robotInventory[robot.collects, default: 0] += 1
        for (material, cost) in robot.costs {
            newState.materialInventory[material]! -= cost
        }

        // good spot to ignore any robots that I already have "enough" of
        var satisfiedRobots = Set<Material>()
        for (material, maxCount) in maximumRobotsNeeded {
            if newState.robotInventory[material, default: 0] >= maxCount {
                satisfiedRobots.insert(material)
            }
        }
        newState.ignoredRobotTypes = satisfiedRobots

        return newState
    }

    func ignoring(_ robotTypes: Set<Material>) -> FactoryState {
        var newState = self

        newState.ignoredRobotTypes = robotTypes

        return newState
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
