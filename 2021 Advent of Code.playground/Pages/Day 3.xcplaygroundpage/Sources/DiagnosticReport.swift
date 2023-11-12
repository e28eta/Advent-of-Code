import Foundation

enum Bit: Character, CaseIterable {
    case zero = "0", one = "1"

    var value: Int {
        switch self {
        case .zero: return 0
        case .one: return 1
        }
    }
}

extension Array where Element: Hashable {
    func elementFrequencies() -> [Element: Int] {
        return reduce(into: [:]) { (freq, element) in
            freq[element, default: 0] += 1
        }
    }
}

struct Number {
    let bits: [Bit]

    init?(_ line: String) {
        bits = line.compactMap({ Bit(rawValue: $0) })

        if bits.isEmpty { return nil }
    }

    func decimal() -> Int {
        return bits.reduce(0) { val, next in
            (val << 1) + next.value
        }
    }
}

public struct DiagnosticReport {
    let ratings: [Number]

    public init(_ string: String) {
        ratings = string.lines().compactMap(Number.init)
    }

    public func part1() -> Int {
        let bitCount = ratings.map(\.bits.count).max() ?? 0

        var gamma = 0, epsilon = 0
        for bit in (0 ..< bitCount) {
            let frequencies = ratings.map({ $0.bits[bit] }).elementFrequencies()
            let isOneMorePopular = frequencies[.one, default: 0] >= frequencies[.zero, default: 0]

            gamma = (gamma << 1) + (isOneMorePopular ? 1 : 0)
            epsilon = (epsilon << 1) + (isOneMorePopular ? 0 : 1)
        }

        return gamma * epsilon
    }

    func oxygenGeneratorRating() -> Int {
        var remainingRatings = ratings
        var bitIndex = 0

        while remainingRatings.count > 1 {
            let frequencies = remainingRatings.map {
                $0.bits[bitIndex]
            }.elementFrequencies()

            let bitToKeep = frequencies[.one, default: 0] >= frequencies[.zero, default: 0] ? Bit.one : .zero
            remainingRatings = remainingRatings.filter {
                $0.bits[bitIndex] == bitToKeep
            }

            bitIndex += 1
        }

        return remainingRatings.first!.decimal()
    }

    func co2ScrubberRating() -> Int {
        var remainingRatings = ratings
        var bitIndex = 0

        while remainingRatings.count > 1 {
            let frequencies = remainingRatings.map {
                $0.bits[bitIndex]
            }.elementFrequencies()

            let bitToKeep = frequencies[.one, default: 0] >= frequencies[.zero, default: 0] ? Bit.zero : .one
            remainingRatings = remainingRatings.filter {
                $0.bits[bitIndex] == bitToKeep
            }

            bitIndex += 1
        }

        return remainingRatings.first!.decimal()
    }

    public func part2() -> Int {
        return oxygenGeneratorRating() * co2ScrubberRating()
    }
}
