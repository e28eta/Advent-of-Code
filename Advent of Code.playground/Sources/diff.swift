import Foundation

public func diff(_ a: UInt, _ b: UInt) -> UInt {
    return max(a, b) - min(a, b)
}

public func diff(_ a: Int, _ b: Int) -> Int {
    return max(a, b) - min(a, b)
}
