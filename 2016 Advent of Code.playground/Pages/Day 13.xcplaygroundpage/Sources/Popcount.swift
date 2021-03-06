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
