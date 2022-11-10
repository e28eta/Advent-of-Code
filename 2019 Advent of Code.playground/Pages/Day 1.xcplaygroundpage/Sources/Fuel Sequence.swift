import Foundation

public struct FuelSequence: Sequence {
    private let initialMass: Int
    public init(_ mass: Int) {
        self.initialMass = mass
    }

    public func makeIterator() -> AnyIterator<Int> {
        var currentMass = initialMass

        return AnyIterator {
            currentMass = (currentMass / 3) - 2
            return currentMass > 0 ? currentMass : nil
        }
    }
}
