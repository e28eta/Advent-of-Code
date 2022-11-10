import Foundation

public func fuelSequence(_ mass: Int) -> some Sequence<Int> {
    // sequence(first: next:) and sequence(state: next:) look great, hope I remember them
    return sequence(state: mass) { mass in
        mass = (mass / 3) - 2
        return mass > 0 ? mass : nil
    }
}
