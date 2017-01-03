//: [Previous](@previous)

/*:
 # Day 16: Dragon Checksum

 You're done scanning this part of the network, but you've left traces of your presence. You need to overwrite some disks with random-looking data to cover your tracks and update the local security system with a new checksum for those disks.

 For the data to not be suspicious, it needs to have certain properties; purely random data will be detected as tampering. To generate appropriate random data, you'll need to use a modified [dragon curve](https://en.wikipedia.org/wiki/Dragon_curve).

 Start with an appropriate initial state (your puzzle input). Then, so long as you don't have enough data yet to fill the disk, repeat the following steps:

 * Call the data you have at this point "a".
 * Make a copy of "a"; call this copy "b".
 * Reverse the order of the characters in "b".
 * In "b", replace all instances of `0` with `1` and all `1`s with `0`.
 * The resulting data is "a", then a single `0`, then "b".

 For example, after a single step of this process,

 * `1` becomes `100`.
 * `0` becomes `001`.
 * `11111` becomes `11111000000`.
 * `111100001010` becomes `1111000010100101011110000`.

 Repeat these steps until you have enough data to fill the desired disk.

 Once the data has been generated, you also need to create a checksum of that data. Calculate the checksum **only** for the data that fits on the disk, even if you generated more data than that in the previous step.

 The checksum for some given data is created by considering each non-overlapping **pair** of characters in the input data. If the two characters match (`00` or `11`), the next checksum character is a `1`. If the characters do not match (`01` or `10`), the next checksum character is a `0`. This should produce a new string which is exactly half as long as the original. If the length of the checksum is **even**, repeat the process until you end up with a checksum with an **odd** length.

 For example, suppose we want to fill a disk of length `12`, and when we finally generate a string of at least length `12`, the first `12` characters are `110010110100`. To generate its checksum:

 * Consider each pair: `11`, `00`, `10`, `11`, `01`, `00`.
 * These are same, same, different, same, different, same, producing `110101`.
 * The resulting string has length `6`, which is **even**, so we repeat the process.
 * The pairs are `11` (same), `01` (different), `01` (different).
 * This produces the checksum `100`, which has an **odd** length, so we stop.

 Therefore, the checksum for `110010110100` is `100`.

 Combining all of these steps together, suppose you want to fill a disk of length `20` using an initial state of `10000`:

 * Because `10000` is too short, we first use the modified dragon curve to make it longer.
 * After one round, it becomes `10000011110` (`11` characters), still too short.
 * After two rounds, it becomes `10000011110010000111110` (`23` characters), which is enough.
 * Since we only need `20`, but we have `23`, we get rid of all but the first `20` characters: `10000011110010000111`.
 * Next, we start calculating the checksum; after one round, we have `0111110101`, which `10` characters long (**even**), so we continue.
 * After two rounds, we have `01100`, which is `5` characters long (**odd**), so we are done.

 In this example, the correct checksum would therefore be `01100`.

 The first disk you have to fill has length `272`. Using the initial state in your puzzle input, **what is the correct checksum**?

 Your puzzle input is `11110010111001001`.
 */

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
    init(_ bits: [Bit]) {
        self = bits.reduce("") { $0 + $1.description }
    }

    func toBits() -> [Bit] {
        return self.utf8.map { Bit($0) }
    }
}

enum Bit: CustomStringConvertible {
    case zero, one

    init(_ character: String.UTF8View.Iterator.Element) {
        switch character {
        case "0".utf8.first!: self = .zero
        case "1".utf8.first!: self = .one
        default: fatalError()
        }
    }

    var description: String {
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

class DragonCurve {
    private let numBits: Int
    private let bits: [Bit]
    private let joiningBits: [Bit]
    private let length: Int

    convenience init(_ bits: String, length: Int? = nil) {
        self.init(bits.toBits(), length: length)
    }

    init(_ bits: [Bit], length: Int? = nil) {
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

    func toString() -> String {
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

    func checksum() -> [Bit] {
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

assert(DragonCurve("1").toString() == "100")
assert(DragonCurve("0").toString() == "001")
assert(DragonCurve("11111").toString() == "11111000000")
assert(DragonCurve("111100001010").toString() == "1111000010100101011110000")

assert(DragonCurve("10000", length: 20).toString() == "10000011110010000111")



func checksum(_ bits: [Bit]) -> [Bit] {
    var result = bits

    repeat {
        result = result.pairs().map {
            switch ($0, $1) {
            case (.zero, .zero), (.one, .one):
                return .one
            case (.zero, .one), (.one, .zero):
                return .zero
            }
        }
    } while result.count % 2 == 0

    return result
}

let exampleChecksumCurve = DragonCurve("1100101101", length: 12)
assert(exampleChecksumCurve.toString() == "110010110100")
assert(exampleChecksumCurve.checksum() == "100".toBits())
assert(DragonCurve("10000", length: 20).checksum() == "01100".toBits())

let input = "11110010111001001".toBits()

let part1Answer = DragonCurve(input, length: 272).checksum()
assert(part1Answer == "01110011101111011".toBits())



/*:
 # Part Two

 The second disk you have to fill has length 35651584. Again using the initial state in your puzzle input, what is the correct checksum for this disk?
 */

// let part2Answer = checksum(dragonCurve(input, length: 35651584))
// print(String(part2Answer))


//: [Next](@next)
