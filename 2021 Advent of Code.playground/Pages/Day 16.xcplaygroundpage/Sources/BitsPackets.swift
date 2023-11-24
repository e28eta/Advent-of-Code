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
    case literal// = 4
    case op(Int)

    init(_ int: Int) {
        switch int {
        case 4: self = .literal
        default: self = .op(int)
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

public struct Packet {
    let version: Int
    let type: PacketType
    let length: OperatorLength?
    let subpackets: [Packet]?

    public static func parse(_ bits: inout ArraySlice<Bit>) -> Packet? {
        let version = bits.prefix(3).intValue()
        bits = bits.dropFirst(3)

        let type = PacketType(bits.prefix(3).intValue())
        bits = bits.dropFirst(3)

        var operatorLength: OperatorLength?
        var subpackets: [Packet]?

        switch type {
        case .literal:
            let val = readLiteral(&bits)

            // p1 doesn't care about the contents
            print("literal with value \(val)")

            operatorLength = nil
            subpackets = nil
        case .op:
            operatorLength = OperatorLength(&bits)

            switch operatorLength! {
            case .bits(let bitCount):
                var slice = bits.prefix(bitCount)
                bits = bits.dropFirst(bitCount)

                subpackets = []
                while !slice.isEmpty, let packet = parse(&slice) {
                    subpackets!.append(packet)
                }
            case .packets(let packetCount):
                subpackets = (0 ..< packetCount).map { _ in parse(&bits)! }
            }
        }

        return Packet(version: version,
                      type: type,
                      length: operatorLength,
                      subpackets: subpackets)
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
        return version + (subpackets?.reduce(0) { s, p in s + p.versionSum() } ?? 0)
    }
}
