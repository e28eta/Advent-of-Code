import Foundation

public struct Point: CustomStringConvertible {
    public var x: Int, y: Int

    public init(x: Int, y: Int) { self.x = x; self.y = y }
    public init(_ s: String) {
        let components = s.split(separator: ",")
        x = Int(components[0])!
        y = Int(components[1])!
    }
    public var description: String { return "(\(x), \(y))" }

    public func manhattanDistance(to other: Self) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }
}
