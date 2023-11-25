import Foundation

public func xValues(_ velocity: Int) -> some Sequence<Int> {
    var velocity = velocity
    return sequence(first: 0) { loc in
        if velocity > 0 {
            defer { velocity -= 1 }
            return loc + velocity
        } else if velocity == 0 {
            return nil
        } else {
            defer { velocity += 1 }
            return loc + velocity
        }
    }
}

public func validXVelocities(passingThrough range: ClosedRange<Int>) -> some Collection<Int> {
    precondition(range.lowerBound >= 0, "TODO")

    // very generous upperBound
    return (0...range.upperBound)
        .filter { velocity in
            xValues(velocity).contains { range.contains($0) }
        }
}

public func xVelocities(stoppingIn range: ClosedRange<Int>) -> some Collection<Int> {
    precondition(range.lowerBound >= 0, "TODO")

    // very generous upperBound
    return (0...range.upperBound)
        .filter { velocity in
            range.contains(xValues(velocity).suffix(1)[0])
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
    return (0 ... abs(range.lowerBound))
        .map(VerticalVelocity.init)
        .filter { velocity in
            let bottomYValue = velocity.yValues(limitedTo: range.lowerBound).suffix(1)[0]
            return range.contains(bottomYValue)
        }
}

public struct VerticalVelocity {
    public let initial: Int
    public let peak: Int
    public let velocityFallingThroughZero: Int

    public init(initial: Int) {
        self.initial = initial
        // triangular number https://oeis.org/A000217
        self.peak = (initial) * (initial + 1) / 2
        // extrapolation from
        self.velocityFallingThroughZero = -1 - initial
    }

    public func yValues(limitedTo limit: Int) -> some Sequence<Int> {
        var velocity = initial

        return sequence(first: 0) { loc in
            let newLoc = loc + velocity
            velocity -= 1
            // fell out the bottom of the target area
            if newLoc < limit && velocity < 0 {
                return nil
            } else {
                return newLoc
            }
        }
    }
}
