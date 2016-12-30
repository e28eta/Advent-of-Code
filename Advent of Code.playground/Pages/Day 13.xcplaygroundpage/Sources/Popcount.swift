import Foundation

extension UInt {
    public func popcount() -> UInt {
        var copy = self
        var result = UInt(0)

        while copy > 0 {
            result += copy & 1
            copy >>= 1
        }

        return result
    }
}

public func diff(_ a: UInt, _ b: UInt) -> UInt {
    return max(a, b) - min(a, b)
}
