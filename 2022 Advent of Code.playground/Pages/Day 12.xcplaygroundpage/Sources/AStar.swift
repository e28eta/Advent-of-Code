import Foundation

/**
 Implement this protocol to track AStar search states: probably need at least a reference to the full area to
 search, as well as a current location in the area
 */
public protocol SearchState: Hashable {
    typealias Cost = Int
    typealias Step = (cost: Cost, state: Self)

    /// Estimated cost from current location to the provided location. Probably shouldn't do a lot of
    /// computation, but semi-accurate causes the search to perform better.
    ///
    /// Must *always* be the same value for any pair of states, cannot subsequently refine.
    /// Must under-estimate the cost to reach the goal
    func estimatedCost(toReach goal: Self) -> Cost

    /// Provide a sequence (possibly lazily computed) of every adjacent step from this state, and the cost
    /// to reach that state from here.
    func adjacentStates() -> any Sequence<Step>
}

/**
 Internal wrapper around SearchState, adding additional info like the goal being worked toward, and the parent
 steps that led to this.
 */
private class SearchStateStep<State: SearchState> {
    let state: State
    let goal: State
    let parent: SearchStateStep<State>?
    let cost: State.Cost
    let totalCost: State.Cost

    init(state: State, goal: State, parent: SearchStateStep<State>? = nil, cost: State.Cost = 0) {
        self.state = state
        self.goal = goal
        self.parent = parent
        self.cost = cost
        self.totalCost = cost + (self.parent?.totalCost ?? 0)
    }

    /// return sequence from goal to start state, following the parent references
    func pathToInitial() -> some Sequence<SearchStateStep<State>> {
        sequence(first: self, next: \.parent)
    }
}

// required for storing into the BinaryHeap. Use
extension SearchStateStep: Comparable where State.Cost: Comparable {
    static func <(_ lhs: SearchStateStep<State>, _ rhs: SearchStateStep<State>) -> Bool {
        assert(lhs.goal == rhs.goal, "When comparing two SearchStateSteps, they must have the same goal")
        // using estimated cost for priority to pull off the heap
        return lhs.totalCost + lhs.state.estimatedCost(toReach: lhs.goal) < rhs.totalCost + rhs.state.estimatedCost(toReach: rhs.goal)
    }

    static func ==(_ lhs: SearchStateStep<State>, _ rhs: SearchStateStep<State>) -> Bool {
        return lhs.state == rhs.state
    }
}

extension SearchStateStep: CustomStringConvertible {
    var description: String {
        return "\(parent?.description ?? "") -\(cost)-> \(state)"
    }
}

/**
 Implementation of A-star search, simply by implementing SearchState protocol
 */
public class AStarSearch<State: SearchState> where State.Cost: Comparable {
    private typealias Step = SearchStateStep<State>
    public typealias SearchResult = (cost: State.Cost, steps: [State])
    let initial: State, goal: State

    public init(initial: State, goal: State) {
        self.initial = initial
        self.goal = goal
    }

    /**
     Find the shortest path between `initial` and `goal` states provided during `init`

     Returns the cost of the path, and each Step along the way
     */
    public func shortestPath() -> SearchResult? {
        var iterator = allPaths().makeIterator()
        return iterator.next()
    }

    /**
     Find the longest path between `initial` and `goal` states provided during `init`

     Returns the cost of the path, and each step along the way
     */
    public func longestPath() -> SearchResult? {
        return allPaths().suffix(1).last
    }

    /**
     All (non-looping) paths that lead to the goal state, lazily computed
     */
    func allPaths() -> some Sequence<SearchResult> {
        return AnySequence<SearchResult> {
            // per a* algorithm definitions
            let openList = BinaryHeap<Step>()
            var closedList = Set<State>()

            openList.push(Step(state: self.initial, goal: self.goal))

            return AnyIterator<SearchResult> {
                while let current = openList.pop() {
                    if closedList.contains(current.state) {
                        continue
                    }

                    if current.state == self.goal {
                        return self.path(to: current)
                    } else {
                        closedList.insert(current.state)

                        for adjacentState in current.state.adjacentStates() {
                            if closedList.contains(adjacentState.state) {
                                continue
                            }

                            let step = Step(state: adjacentState.state,
                                            goal: self.goal,
                                            parent: current,
                                            cost: adjacentState.cost)

                            openList.push(step)
                        }
                    }
                }

                return nil
            }
        }
    }

    private func path(to goal: Step) -> (cost: State.Cost, steps: [State]) {
        return (cost: goal.totalCost,
                steps: goal.pathToInitial().map(\Step.state).reversed()
        )
    }
}
