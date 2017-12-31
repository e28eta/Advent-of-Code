import Foundation

public struct KnotHash {
    public var list: [UInt8]
    var current: Array<Int>.Index
    var skip = 0

    public init(_ size: UInt8) {
        list = Array(0...size)
        current = list.startIndex
    }

    mutating func apply(_ length: Int) {
        let range = (current ..< (current + length))

        for (left, right) in zip(range, range.reversed()).prefix(range.count / 2) {
            list.swapAt(list.index(wrapping: left),
                        list.index(wrapping: right))
        }

        current = list.index(wrapping: current + length + skip)
        skip += 1
    }

    public var checksum: Int {
        guard list.count > 1 else { return 0 }
        return Int(list[0]) * Int(list[1])
    }

    public var denseHash: String {
        return list.taking(chunksOf: 16)
            .map { $0.reduce(0, ^) }
            .map { String(format: "%02x", $0) }
            .joined(separator: "")
    }

    @discardableResult public mutating func apply(_ lengths: [Int], rounds: Int = 1) -> KnotHash {
        for _ in (0..<rounds) {
            for length in lengths {
                apply(length)
            }
        }

        return self
    }

    public static func hash(_ string: String) -> String {
        let lengths = string.utf8.map { Int($0) } + [17, 31, 73, 47, 23]

        var knotHash = KnotHash(255)
        knotHash.apply(lengths, rounds: 64)

        return knotHash.denseHash
    }
}
