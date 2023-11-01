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

    struct SearchState {
        /// valve (un-opened) where I'm currently standing
        let currentValve: String
        /// valves that haven't been opened yet
        let remaining: Set<String>
        /// current pressure relieved along this path
        var pressureRelieved: Int
        /// time remaining along this path
        var timeRemaining: Int

        /// track pressure of unopened valves to prune branches when
        /// they couldn't possibly make a difference
        var pendingPressure: Int
    }

    public func calculateBestPressureRelief() -> Int {
        var bestPressure = 0
        var searchStateQueue = [
            SearchState(currentValve: startingLocation,
                        remaining: Set(valuableValves.keys).subtracting([startingLocation]),
                        pressureRelieved: 0,
                        timeRemaining: 30,
                        pendingPressure: valuableValves.reduce(0, { $0 + $1.value }))
        ]

        while !searchStateQueue.isEmpty {
            var currentState = searchStateQueue.removeFirst()

            if let value = valuableValves[currentState.currentValve], value > 0 {
                // open this valve & count its value.
                // Expected for every valve except possibly the starting one
                currentState.timeRemaining -= 1
                currentState.pressureRelieved += currentState.timeRemaining * value
                currentState.pendingPressure -= value

                bestPressure = max(currentState.pressureRelieved, bestPressure)
            }

            // check every remaining valuable valve
            for nextValve in currentState.remaining {
                let pathCost = cost(from: currentState.currentValve, to: nextValve)
                let remainingTime = currentState.timeRemaining - pathCost

                // Verify there's enough time for this to be worth traveling to
                // +2: one to open valve, one to count some pressure
                guard remainingTime >= 2 else {
                    continue
                }

                let upperBoundValue = (remainingTime - 2) * currentState.pendingPressure
                guard currentState.pressureRelieved + upperBoundValue > bestPressure else {
                    // not enough time + pressure remaining to make this worth pursuing
                    // Wow! This check saves a bunch of runtime
                    continue
                }

                searchStateQueue.append(
                    SearchState(currentValve: nextValve,
                                remaining: currentState.remaining.subtracting([nextValve]),
                                pressureRelieved: currentState.pressureRelieved,
                                timeRemaining: remainingTime,
                                pendingPressure: currentState.pendingPressure))
            }
        }

        return bestPressure
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
