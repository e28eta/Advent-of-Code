import Foundation

public func gcd<T: BinaryInteger>(_ x: T, _ y: T) -> T {
    var a = Swift.max(x, y),
        b = Swift.min(x, y)

    while b != 0 {
        (a, b) = (b, a % b)
    }

    return a
}

public func lcm<T: BinaryInteger>(_ x: T, _ y: T) -> T {
    return x / gcd(x, y) * y
}

public func lcm<T: BinaryInteger>(_ values: [T]) -> T {
    values.reduce(1, lcm)
}
