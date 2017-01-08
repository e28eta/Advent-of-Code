//: [Previous](@previous)

/*:
 # Day 22: Grid Computing

 You gain access to a massive storage cluster arranged in a grid; each storage node is only connected to the four nodes directly adjacent to it (three if the node is on an edge, two if it's in a corner).

 You can directly access data **only** on node `/dev/grid/node-x0-y0`, but you can perform some limited actions on the other nodes:

 * You can get the disk usage of all nodes (via `[df](https://en.wikipedia.org/wiki/Df_(Unix)#Example)`). The result of doing this is in your puzzle input.
 * You can instruct a node to **move** (not copy) **all** of its data to an adjacent node (if the destination node has enough space to receive the data). The sending node is left empty after this operation.

 Nodes are named by their position: the node named `node-x10-y10` is adjacent to nodes `node-x9-y10`, `node-x11-y10`, `node-x10-y9`, and `node-x10-y11`.

 Before you begin, you need to understand the arrangement of data on these nodes. Even though you can only move data between directly connected nodes, you're going to need to rearrange a lot of the data to get access to the data you need. Therefore, you need to work out how you might be able to shift data around.

 To do this, you'd like to count the number of **viable pairs** of nodes. A viable pair is any two nodes (A,B), **regardless of whether they are directly connected**, such that:

 * Node A is **not** empty (its `Used` is not zero).
 * Nodes A and B are **not the same** node.
 * The data on node A (its `Used`) would fit on node B (its `Avail`).

 **How many viable pairs** of nodes are there?
 
 */

import Foundation

struct Coordinate: Equatable, Comparable {
    let x: Int, y: Int

    init(_ string: String) {
        let components = string.components(separatedBy: "-")

        let x = components[0].replacingOccurrences(of: "x", with: "")
        let y = components[1].replacingOccurrences(of: "y", with: "")

        self.x = Int(x, radix: 10)!
        self.y = Int(y, radix: 10)!
    }

    static func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    static func <(lhs: Coordinate, rhs: Coordinate) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        } else {
            return lhs.y < rhs.y
        }
    }
}

struct Node: Equatable {
    let location: Coordinate

    let avail: Int
    let used: Int

    init?(_ string: String) {
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

    static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.location == rhs.location
    }
}

struct Datacenter {
    let nodes: [Node]
    typealias AvailableAndCount = (avail: Int, count: Int)
    let descendingAvailAndCount: [AvailableAndCount]

    init(_ string: String) {
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
    }


    func viablePairs() -> Int {
        return self.nodes.reduce(0) { (sum, node) in
            return sum + node.viablePairs(self.descendingAvailAndCount)
        }
    }


}

let input = try readResourceFile("input.txt")
let datacenter = Datacenter(input)

let part1 = datacenter.viablePairs()
assert(part1 == 987)

//: [Next](@next)
