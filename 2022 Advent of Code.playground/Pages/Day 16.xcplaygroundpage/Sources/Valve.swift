import Foundation
import RegexBuilder

public struct Volcano {
    /// fixed starting location
    public let startingLocation = "AA"
    /// full graph of valves
    public let valveGraph: ValveGraph
    /// Only valves with positive pressure rates
    public let valuableValves: [String: Int]
    /// for every interesting valve, shortest paths to every other valve
    let dijkstraGraphs: [String: Dijkstra<ValveGraph>]

    public init(_ string: String) {
        let valves = Valve.valves(from: string)
        let valveGraph = ValveGraph(valves)
        let valuableValves = valveGraph.vertices.filter { $0.value > 0 }

        self.valveGraph = valveGraph
        self.valuableValves = valuableValves
        self.dijkstraGraphs = ([startingLocation] + valuableValves.keys).reduce(into: [:]) { (d, name) in
            d[name] = Dijkstra(graph: valveGraph, initialVertex: name)
        }
    }

    public func cost(from start: String, to end: String) -> Int {
        guard let graph = dijkstraGraphs[start],
              let calculated = graph.cost[end] else {
            fatalError("didn't calculate \(start) -> \(end)")
        }

        return calculated
    }

    public func calculateBestPressureRelief() -> Int {
        var bestPressure = 0
        let timeLimit = 30

        allFeasiblePaths(timeLimit: timeLimit) { path in
            bestPressure = max(bestPressure, path.pressureRelieved(startTime: timeLimit))
        }

        return bestPressure
    }

    public func calculateBestPressureWithElephantsHelp() -> Int {
        var bestPressures: [Set<String>: Int] = [:]
        let timeLimit = 26

        allFeasiblePaths(timeLimit: 26) { path in
            let pathComponents = Set(path.valves)

            bestPressures[pathComponents] = max(bestPressures[pathComponents, default: 0], path.pressureRelieved(startTime: timeLimit))
        }

        var combinedPressures = 0
        for combo in bestPressures.combinations(ofCount: 2) {
            let (left, right) = (combo[0], combo[1])
            if left.key.isDisjoint(with: right.key) {
                combinedPressures = max(combinedPressures, left.value + right.value)
            }
        }

        return combinedPressures
    }

    struct AllPathsState {
        var currentValve: String
        var path: ValvePathSegment

        var remainingValves: Set<String>
    }

    func allFeasiblePaths(timeLimit: Int, _ visit: (ValvePathSegment) -> ()) {

        var searchStateQueue = [
            // both starting locations are worth 0 flow, simplifies
            AllPathsState(currentValve: startingLocation,
                          path: ValvePathSegment(),
                          remainingValves: Set(valuableValves.keys))
        ]

        while !searchStateQueue.isEmpty {
            let currentState = searchStateQueue.removeLast()

            // check every remaining valuable valve
            for nextValve in currentState.remainingValves {
                let nextPath = currentState.path.adding(valve: nextValve,
                                                        cost: cost(from: currentState.currentValve, to: nextValve),
                                                        rate: valuableValves[nextValve, default: 0])

                if nextPath.timeRequired > timeLimit {
                    continue
                }

                visit(nextPath)

                searchStateQueue.append(
                    AllPathsState(currentValve: nextValve,
                                  path: nextPath,
                                  remainingValves: currentState.remainingValves.subtracting([nextValve]))
                )
            }
        }
    }
}

public struct Valve {
    public let name: String
    public let rate: Int
    public let tunnels: [String]
}

public struct ValveGraph: DijkstraGraph {
    public typealias Cost = Int
    public typealias FlowRate = Int

    /// source vertex to list of destination vertices
    public let edges: [String: [String]]
    /// vertex to value of vertex, all vertices in the graph
    public let vertices: [String: FlowRate]

    init(_ valves: [Valve]) {
        // assumes no Valves with duplicate names
        edges = valves.reduce(into: [:]) { (d, v) in d[v.name] = v.tunnels }

        vertices = valves.reduce(into: [:]) { (d, v) in
            d[v.name] = v.rate
        }
    }

    public func allVertices() -> any Sequence<String> {
        return vertices.keys
    }

    public func neighbors(of valve: String) -> any Sequence<(Int, String)> {
        return (edges[valve] ?? []).map { (1, $0) }
    }
}

public struct ValvePathSegment {
    /// valves that make up this path segment
    var valves: [String]

    /// amount of time required to traverse this segment and open the valves
    /// since getting to first segment takes varying time, this is time to open first valve,
    /// travel to next valve, open that valve, etc
    var timeRequired: Int

    /**
     Pressure relieved along this path is linear along time remaining when the valves
     are opened.

     pressure(t) = t * (sum of rates)
     - (time spent to open first * rate of first)
     - (time spent to open first & second * rate of second)
     - (time spent to open first through third * rate of third)

     Only valid when `t >= timeRequired`.
     If `(t * sum of rates)` was really large, might make sense to re-write as
     `(t - timeRequired) * (sum of rates) + <constant...>`
     */
    struct PressureEquation {
        /// multiplicative factor against time when segment started
        var multiplier: Int
        /// constant factor, stored as negative number
        var constant: Int
    }
    var pressureEquation: PressureEquation

    init() {
        // empty path, for initial state
        self.valves = []
        self.timeRequired = 0
        self.pressureEquation = PressureEquation(multiplier: 0, constant: 0)
    }

    /// amount of pressure relieved traversing this segment starting at `startTime`
    func pressureRelieved(startTime: Int) -> Int {
        // handle this case by having shorter path segments
        guard startTime >= timeRequired else { return 0 }

        return pressureEquation.multiplier * startTime + pressureEquation.constant
    }

    func adding(valve: String, cost: Int, rate: Int) -> ValvePathSegment {
        var newSegment = self

        newSegment.valves.append(valve)
        newSegment.timeRequired += cost + 1
        newSegment.pressureEquation.multiplier += rate
        newSegment.pressureEquation.constant -= newSegment.timeRequired * rate

        return newSegment
    }
}

extension ValvePathSegment: CustomStringConvertible {
    public var description: String {
        return valves.joined(separator: " -> ") + " (\(timeRequired)): \(pressureEquation)"
    }
}

extension ValvePathSegment.PressureEquation: CustomStringConvertible {
    public var description: String {
        return "v(t) = t * \(multiplier) - \(constant * -1)"
    }
}

let EnglishLocale = Locale(identifier: "en-US")
extension Valve {
    static let NameRef = Reference<Substring>()
    static let RateRef = Reference<Int>()
    static let TunnelsRef = Reference<[String]>()

    static let MatchingRegex = Regex {
        Anchor.startOfLine
        "Valve "
        Capture(as: NameRef) { OneOrMore(.word) }
        " has flow rate="
        Capture(.localizedInteger(locale: EnglishLocale), as: RateRef)
        ChoiceOf {
            "; tunnel leads to valve "
            "; tunnels lead to valves "
        }
        Capture(as: TunnelsRef) {
            ZeroOrMore {
                OneOrMore(.word)
                ", "
            }
            OneOrMore(.word)
        } transform: {
            $0.components(separatedBy: ", ")
        }
        Optionally(Anchor.endOfLine)
    }

    public static func valves(from string: String) -> [Valve] {
        return string.matches(of: MatchingRegex)
            .map { match in
                Valve(name: String(match[NameRef]),
                      rate: match[RateRef],
                      tunnels: match[TunnelsRef])
            }
    }
}

extension Valve {
    public func dotviz() -> String {
        return "\(name) [label=\"\(rate)\"];\n" +
        "\(name) -- {\(tunnels.joined(separator: " "))};"
    }
}

extension Dijkstra where Graph.Vertex: CustomStringConvertible {
    public func dotviz(graphName: String = "D") -> String {
        return """
digraph \(graphName) {

""" +
        previous.map({ (key, value) -> String in
            "\t\(value) -> \(key)\n"
        }).joined()
        + """
}
"""
    }
}
