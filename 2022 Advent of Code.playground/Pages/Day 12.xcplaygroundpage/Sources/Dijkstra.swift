import Foundation

public protocol DijkstraGraph {
    associatedtype Vertex: Hashable
    associatedtype EdgeCost: FixedWidthInteger

    /**
     Return finite sequence of all vertices in the graph
     */
    func allVertices() -> any Sequence<Vertex>

    /**
     Return finite sequence of all neighbors of a vertex, and the cost to reach them
     */
    func neighbors(of vertex: Vertex) -> any Sequence<(EdgeCost, Vertex)>
}

public class Dijkstra<Graph: DijkstraGraph> {
    typealias Result = (cost: [Graph.Vertex: Graph.EdgeCost],
                        previous: [Graph.Vertex: Graph.Vertex])
    let graph: Graph
    let initialVertex: Graph.Vertex

    let cost: [Graph.Vertex: Graph.EdgeCost]
    let previous: [Graph.Vertex: Graph.Vertex]

    public init(graph: Graph, initialVertex: Graph.Vertex) {
        self.graph = graph
        self.initialVertex = initialVertex

        var cost: [Graph.Vertex: Graph.EdgeCost] = [initialVertex: 0]
        var previous = [Graph.Vertex: Graph.Vertex]()

        var openList = Array(graph.allVertices())
        var closedList = Set<Graph.Vertex>()

        while !openList.isEmpty {
            // choose closest vertex
            let (idx, current) = openList.enumerated().min { left, right in
                cost[left.element, default: .max]
                < cost[right.element, default: .max]
            }!
            openList.remove(at: idx)
            closedList.insert(current)

            guard let currentCost = cost[current] else {
                // cost hasn't been set (aka: infinite), this
                // node isn't reachable from `initialVertex`
                cost[current] = .max
                continue
            }

            for (neighborCost, neighbor) in graph.neighbors(of: current) {
                if closedList.contains(neighbor) {
                    continue
                }

                let totalCost = currentCost + neighborCost
                if totalCost < cost[neighbor, default: .max] {
                    cost[neighbor] = totalCost
                    previous[neighbor] = current
                }
            }
        }

        self.cost = cost
        self.previous = previous
    }
}
