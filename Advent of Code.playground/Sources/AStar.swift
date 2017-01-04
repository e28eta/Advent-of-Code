import Foundation

public protocol SearchState: Hashable {
    typealias Cost = Int
    typealias Step = (cost: Cost, state: Self)

    func estimatedCost(toReach goal: Self) -> Cost

    func adjacentStates() -> AnySequence<Step>
}

private class SearchStateStep<State: SearchState>: Comparable, CustomStringConvertible where State.Cost: Comparable {
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

    static func <(_ lhs: SearchStateStep<State>, _ rhs: SearchStateStep<State>) -> Bool {
        assert(lhs.goal == rhs.goal, "When comparing two SearchStateSteps, they must have the same goal")
        return lhs.totalCost + lhs.state.estimatedCost(toReach: lhs.goal) < rhs.totalCost + rhs.state.estimatedCost(toReach: rhs.goal)
    }

    static func ==(_ lhs: SearchStateStep<State>, _ rhs: SearchStateStep<State>) -> Bool {
        return lhs.state == rhs.state
    }

    var description: String {
        return "\(parent) -\(cost)-> \(state)"
    }

    func pathToInitial() -> AnyIterator<SearchStateStep<State>> {
        var current: SearchStateStep<State>? = self
        return AnyIterator {
            let result = current
            current = current?.parent
            return result
        }
    }
}

public class AStarSearch<State: SearchState> where State.Cost: Comparable {
    private typealias Step = SearchStateStep<State>
    let initial: State, goal: State

    public init(initial: State, goal: State) {
        self.initial = initial
        self.goal = goal
    }

    public func shortestPath() -> (cost: State.Cost, steps: [State])? {
        return allPaths().makeIterator().next()
    }

    public func longestPath() -> (cost: State.Cost, steps: [State])? {
        return allPaths().suffix(1).makeIterator().next()
    }

    public func allPaths() -> AnySequence<(cost: State.Cost, steps: [State])> {
        return AnySequence<(cost: State.Cost, steps: [State])> { () -> AnyIterator<(cost: SearchState.Cost, steps: [State])> in 
            let openList = BinaryHeap<Step>()
            var closedList = Set<State>()

            openList.push(Step(state: self.initial, goal: self.goal))

            return AnyIterator<(cost: State.Cost, steps: [State])> {
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
        return (cost: goal.totalCost, steps: goal.pathToInitial().reversed().map { step in
            return step.state
        })
    }
}
