import Foundation
import RegexBuilder

public enum Bit {
    case zero, one

    init(_ value: some Numeric) {
        switch value {
        case 0: self = .zero
        case 1: self = .one
        default: fatalError("value out of range \(value)")
        }
    }

    var value: Int {
        switch self {
        case .zero:
            return 0
        case .one:
            return 1
        }
    }
}

extension Collection where Element == Bit {
    public func intValue() -> Int {
        return self.reduce(0) { v, b in
            (v << 1) + b.value
        }
    }
}

extension Bit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        }
    }
}

public func hexToBinary(_ string: String) -> some Collection<Bit> {
    return string.sliced(into: 2).flatMap { (digits) -> [Bit] in
        guard let uint = UInt8(digits, radix: 16) else { return [] }

        // probably an easier way to do this, but I don't think it really matters
        var remaining = uint
        return Array((0 ..< uint.bitWidth).map { _ in
            let (q, r) = remaining.quotientAndRemainder(dividingBy: 2)
            remaining = q
            return Bit(r)
        }.reversed())
    }
}


enum PacketType {
    case sum
    case product
    case minimum
    case maximum
    case literal
    case greaterThan
    case lessThan
    case equalTo

    init(_ int: Int) {
        switch int {
        case 0: self = .sum
        case 1: self = .product
        case 2: self = .minimum
        case 3: self = .maximum
        case 4: self = .literal
        case 5: self = .greaterThan
        case 6: self = .lessThan
        case 7: self = .equalTo
        default: fatalError("unsupported PacketType \(int)")
        }
    }
}

enum OperatorLength {
    case bits(Int)
    case packets(Int)

    init(_ bits: inout ArraySlice<Bit>) {
        let type = bits.popFirst()!

        switch type {
        case .zero:
            let len = bits.prefix(15).intValue()
            bits = bits.dropFirst(15)
            self = .bits(len)
        case .one:
            let count = bits.prefix(11).intValue()
            bits = bits.dropFirst(11)
            self = .packets(count)
        }
    }
}

enum PacketContent {
    case value(Int)
    case subpackets([Packet])
}

public struct Packet {
    let version: Int
    let type: PacketType
    let content: PacketContent

    public static func parse(_ bits: inout ArraySlice<Bit>) -> Packet? {
        let version = bits.prefix(3).intValue()
        bits = bits.dropFirst(3)

        let type = PacketType(bits.prefix(3).intValue())
        bits = bits.dropFirst(3)

        let content: PacketContent
        if case .literal = type {
            content = .value(readLiteral(&bits))
        } else {
            let operatorLength = OperatorLength(&bits)

            switch operatorLength {
            case .bits(let bitCount):
                var slice = bits.prefix(bitCount)
                bits = bits.dropFirst(bitCount)

                var subpackets: [Packet] = []
                while !slice.isEmpty, let packet = parse(&slice) {
                    subpackets.append(packet)
                }

                content = .subpackets(subpackets)
            case .packets(let packetCount):
                content = .subpackets((0 ..< packetCount).map { _ in parse(&bits)! })
            }
        }

        return Packet(version: version,
                      type: type,
                      content: content)
    }

    public static func readLiteral(_ bits: inout ArraySlice<Bit>) -> Int {
        var literalBits: [Bit] = []
        var keepReading: Bool

        repeat {
            keepReading = bits.popFirst()! == .one
            literalBits.append(contentsOf: bits.prefix(4))
            bits = bits.dropFirst(4)
        } while keepReading

        return literalBits.intValue()
    }

    public func versionSum() -> Int {
        if case .subpackets(let subpackets) = content {
            return version + subpackets.reduce(0) { $0 + $1.versionSum() }
        } else {
            return version
        }
    }

    public func value() -> Int {
        switch content {
        case .value(let value):
            return value
        case .subpackets(let packets):
            switch type {
            case .sum:
                return packets.reduce(0) { $0 + $1.value() }
            case .product:
                return packets.reduce(1) { $0 * $1.value() }
            case .minimum:
                return packets.dropFirst()
                    .reduce(packets.first!.value()) { v, p in
                    return min(v, p.value())
                }
            case .maximum:
                return packets.dropFirst()
                    .reduce(packets.first!.value()) { v, p in
                        return max(v, p.value())
                    }
            case .literal:
                fatalError("packet with type literal but not content = .value")
            case .greaterThan:
                return packets[0].value() > packets[1].value() ? 1 : 0
            case .lessThan:
                return packets[0].value() < packets[1].value() ? 1 : 0
            case .equalTo:
                return packets[0].value() == packets[1].value() ? 1 : 0
            }
        }
    }
}
