import Foundation

public func validXVelocities(landingInside range: ClosedRange<Int>) -> some Collection<HorizontalVelocity> {
    precondition(range.lowerBound >= 0, "TODO")

    // very generous upperBound
    return (0...range.upperBound)
        .map {
            HorizontalVelocity(initial: $0, limit: range.upperBound)
        }
        .filter { velocity in
            range.contains(velocity.xValues.last!)
        }
}

public func validYVelocities(landingInside range: ClosedRange<Int>) -> some Collection<VerticalVelocity> {
    precondition(range.lowerBound < 0,
                 "only handle ranges that're below starting point")

    // as it passes through zero, it has roughly same magnitude of velocity
    // as it had leaving zero the first time. If that velocity is high
    // enough that it falls completely through the target range, can
    // ignore it.
    // Otherwise, this is just brute force, ignoring off-by-one in
    // the safe direction
    return (range.lowerBound ... abs(range.lowerBound))
        .map({ VerticalVelocity(initial: $0, limit: range.lowerBound) })
        .filter { velocity in
            let bottomYValue = velocity.yValues.last!
            return range.contains(bottomYValue)
        }
}

public struct HorizontalVelocity {
    public let initial: Int
    public let xValues: [Int]
    public let lastValueRepeats: Bool

    public init(initial: Int, limit: Int) {
        self.initial = initial

        var velocity = initial
        var xValues = [0]
        var location = 0

        repeat {
            location += velocity

            if location <= limit {
                xValues.append(location)
            } else {
                // flew past limit
                break
            }

            if velocity > 0 {
                velocity -= 1
            } else if velocity < 0 {
                velocity += 1
            }
        } while velocity != 0 // next loc would be same

        self.xValues = xValues
        self.lastValueRepeats = (velocity == 0)
    }

    public func allXValues() -> AnySequence<Int> {
        if lastValueRepeats {
            return AnySequence(chain(xValues, xValues.suffix(1).cycled()))
        } else {
            return AnySequence(xValues)
        }

    }
}

public struct VerticalVelocity {
    public let initial: Int
    public let peak: Int
    public let yValues: [Int]

    public init(initial: Int, limit lowestBound: Int) {
        self.initial = initial

        // triangular number https://oeis.org/A000217
        self.peak = initial > 0 ? (initial) * (initial + 1) / 2 : 0

        var velocity = initial
        self.yValues = Array(sequence(first: 0) { loc in
            let newLoc = loc + velocity
            velocity -= 1
            // fell out the bottom of the target area
            if newLoc < lowestBound && velocity < 0 {
                return nil
            } else {
                return newLoc
            }
        })
    }
}
