import Foundation

extension Sequence {
    func pairs() -> AnySequence<(Self.Iterator.Element, Self.Iterator.Element)> {
        return AnySequence<(Self.Iterator.Element, Self.Iterator.Element)> { () -> AnyIterator<(Self.Iterator.Element, Self.Iterator.Element)> in
            var iterator = self.makeIterator()

            return AnyIterator<(Self.Iterator.Element, Self.Iterator.Element)> {
                guard let first = iterator.next(), let second = iterator.next() else {
                    return nil
                }

                return (first, second)
            }
        }
    }
}

extension String {
    public init(_ bits: [Bit]) {
        self = bits.reduce("") { $0 + $1.description }
    }

    public func toBits() -> [Bit] {
        return self.utf8.map { Bit($0) }
    }
}

public enum Bit: CustomStringConvertible {
    case zero, one

    init(_ character: String.UTF8View.Iterator.Element) {
        switch character {
        case "0".utf8.first!: self = .zero
        case "1".utf8.first!: self = .one
        default: fatalError()
        }
    }

    public var description: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        }
    }

    static public prefix func !(_ bit: Bit) -> Bit {
        switch bit {
        case .zero: return .one
        case .one: return .zero
        }
    }
}

public class DragonCurve {
    private let numBits: Int
    private let bits: [Bit]
    private let joiningBits: [Bit]
    private let length: Int

    public convenience init(_ bits: String, length: Int? = nil) {
        self.init(bits.toBits(), length: length)
    }

    public init(_ bits: [Bit], length: Int? = nil) {
        self.bits = bits + [.zero] + bits.reversed().map(!)
        self.numBits = bits.count

        var joining = [Bit.zero]

        if let length = length {
            while (joining.count * (1 + numBits)) <= length {
                joining = joining + [.zero] + joining.reversed().map(!)
            }
        }

        self.joiningBits = joining
        self.length = length ?? (bits.count * 2 + 1)
    }

    subscript(_ index: Int) -> Bit {
        let bitsPlusJoiner = numBits + 1

        if index % bitsPlusJoiner == numBits {
            // this is a joining bit
            return joiningBits[index / bitsPlusJoiner]
        }

        // not a joining bit, find it in our bits array
        let moduloIndex = index % (2 * bitsPlusJoiner)
        assert(moduloIndex != (bitsPlusJoiner-1) && moduloIndex != bitsPlusJoiner + numBits)

        return bits[moduloIndex]
    }

    subscript(_ range: CountableRange<Int>) -> [Bit] {
        return range.map { self[$0] }
    }

    public func toString() -> String {
        return String(self[(0..<length)])
    }

    func pairs() -> AnySequence<(Bit, Bit)> {
        return AnySequence<(Bit, Bit)> { () -> AnyIterator<(Bit, Bit)> in
            var index = 0
            return AnyIterator<(Bit, Bit)> {
                if index >= self.length {
                    return nil
                } else {
                    defer { index += 2 }
                    return (self[index], self[index+1])
                }
            }
        }
    }

    public func checksum() -> [Bit] {
        let convertPair: ((Bit, Bit) -> Bit) = {
            switch ($0, $1) {
            case (.zero, .zero), (.one, .one):
                return .one
            case (.zero, .one), (.one, .zero):
                return .zero
            }
        }

        var result = self.pairs().map(convertPair)

        while result.count % 2 == 0 {
            result = result.pairs().map(convertPair)
        }

        return result
    }

    func numberOfDigitsPerChecksumDigit() -> Int {
        // shortcut to figure out the largest power of two the number can be evenly divided by.
        // That directly correlates with how many digits of the curve are used for each checksum digit
        return length & -length
    }
}
