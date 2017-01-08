import Foundation

public struct Coordinate: Equatable, Comparable {
    public let x: Int, y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public init(_ string: String) {
        let components = string.components(separatedBy: "-")

        let x = components[0].replacingOccurrences(of: "x", with: "")
        let y = components[1].replacingOccurrences(of: "y", with: "")

        self.x = Int(x, radix: 10)!
        self.y = Int(y, radix: 10)!
    }

    public static func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    public static func <(lhs: Coordinate, rhs: Coordinate) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        } else {
            return lhs.y < rhs.y
        }
    }
}

public struct Node: Equatable {
    public let location: Coordinate

    public var avail: Int
    public var used: Int

    public init?(_ string: String) {
        guard string.hasPrefix("/dev/grid/node-") else { return nil }

        let components = string.replacingOccurrences(of: "/dev/grid/node-", with: "").replacingOccurrences(of: "T", with: "").components(separatedBy: .whitespaces).filter { $0.characters.count > 0 }

        self.location = Coordinate(components[0])

        self.used = Int(components[2], radix: 10)!
        self.avail = Int(components[3], radix: 10)!
    }

    func viablePairs(_ frequencies: [Datacenter.AvailableAndCount]) -> Int {
        guard self.used > 0 else { return 0 }

        var sum = 0

        for (avail, count) in frequencies {
            if self.used <= avail {
                sum += count
            } else {
                break
            }
        }

        if self.used <= self.avail {
            // don't count self
            sum -= 1
        }

        return sum
    }

    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.location == rhs.location
    }
}

public struct Datacenter {
    public let nodes: [Node]

    typealias AvailableAndCount = (avail: Int, count: Int)
    let descendingAvailAndCount: [AvailableAndCount]

    public let maxX: Int, maxY: Int, maxAvailable: Int

    public init(_ string: String) {
        self.nodes = string.components(separatedBy: .newlines).flatMap { Node($0) }

        self.descendingAvailAndCount = self.nodes.reduce([:]) { (hash: [Int: Int], node: Node) -> [Int: Int] in
            var hash = hash
            let count = hash[node.avail] ?? 0
            hash[node.avail] = count + 1

            return hash
            }.map { (avail: Int, count: Int) -> AvailableAndCount in
                return (avail: avail, count: count)
            }.sorted {
                $0.0.avail > $0.1.avail
        }

        self.maxX = self.nodes.map { $0.location.x }.max()!
        self.maxY = self.nodes.map { $0.location.y }.max()!
        self.maxAvailable = self.nodes.map { $0.avail }.max()!
    }


    public func viablePairs() -> Int {
        return self.nodes.reduce(0) { (sum, node) in
            return sum + node.viablePairs(self.descendingAvailAndCount)
        }
    }
}
