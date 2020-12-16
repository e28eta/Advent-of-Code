import Foundation

public struct MemoryGame: Sequence {
    let starting: [Int]


    public init(_ string: String) {
        starting = string.split(separator: ",").compactMap(Int.init)
    }

    public func makeIterator() -> AnyIterator<Int> {
        var previous: Int?
        var turn = 0
        var startingIterator = starting.makeIterator()
        var ages = [Int: Int]()

        return AnyIterator {
            let spoken: Int

            if let startingValue = startingIterator.next() {
                // always just take the starting values
                spoken = startingValue
            } else if let previous = previous, let previousAge = ages[previous] {
                // last turn was *not* the first time previous was spoken
                spoken = turn - previousAge
            } else {
                // last turn *was* the first time it had been said
                spoken = 0
            }

            // update age of previous, if there was one
            if let previous = previous {
                ages[previous] = turn
            }

            // update turn, previous and return the correct value
            turn += 1
            previous = spoken
            return spoken
        }
    }
}
