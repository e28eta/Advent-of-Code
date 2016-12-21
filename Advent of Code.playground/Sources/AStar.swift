import Foundation

/**
 Must be totally ordered via Comparison, and A < B && A > B implies A==B
 */
public protocol SearchState: Hashable, Comparable {
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

    init(state: State, goal: State, parent: SearchStateStep<State>? = nil, cost: State.Cost = 0) {
        self.state = state
        self.goal = goal
        self.parent = parent
        self.cost = cost
    }

    static func <(_ lhs: SearchStateStep<State>, _ rhs: SearchStateStep<State>) -> Bool {
        assert(lhs.goal == rhs.goal, "When comparing two SearchStateSteps, they must have the same goal")
        let leftCostToGoal = lhs.state.estimatedCost(toReach: lhs.goal),
            rightCostToGoal = rhs.state.estimatedCost(toReach: rhs.goal)

        if leftCostToGoal == rightCostToGoal {
            // Since this is being used for Heap ordering too, have to make sure 
            // A < B && A > B implies A==B
            return lhs.state < rhs.state
        } else {
            return leftCostToGoal < rightCostToGoal
        }
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
        let openList = BinaryHeap<Step>()
        var closedList = Set<State>()

        openList.push(Step(state: initial, goal: goal))

        while let current = openList.pop() {
            if current.state == goal {
                return path(to: current)
            } else {
                closedList.insert(current.state)

                for adjacentState in current.state.adjacentStates() {
                    if closedList.contains(adjacentState.state) {
                        continue
                    }

                    let step = Step(state: adjacentState.state,
                                    goal: goal,
                                    parent: current,
                                    cost: adjacentState.cost)
                    if openList.contains(step) {
                        continue
                    }

                    openList.push(step)
                }
            }
        }

        return nil
    }

    private func path(to goal: Step) -> (cost: State.Cost, steps: [State]) {
        return goal.pathToInitial().reversed().reduce((cost: 0, steps: Array<State>())) { (sum: (cost: Int, steps: Array<State>), next: Step) -> (Int, Array<State>) in
            (cost: sum.cost + next.cost, steps: sum.steps + [next.state])
        }
    }
}
