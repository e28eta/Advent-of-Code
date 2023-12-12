import Foundation

public enum CardRank: Character, CaseIterable {
    case Ace = "A", King = "K", Queen = "Q", Jack = "J", Ten = "T",
         Nine = "9", Eight = "8", Seven = "7", Six = "6",
         Five = "5", Four = "4", Three = "3", Two = "2", Joker = "X"
}

public enum HandType {
    case FiveOfAKind, FourOfAKind, FullHouse,
         ThreeOfAKind, TwoPair, OnePair, HighCard
}

public struct CamelCards {
    // lowest to highest
    let rankedHands: [CamelCardHand]

    public func totalWinnings() -> Int {
        return rankedHands.enumerated().reduce(0) { sum, e in
            return sum + (e.offset + 1) * (e.element.bid)
        }
    }
}


public struct CamelCardHand {
    let cards: [CardRank]
    let type: HandType
    let bid: Int

    init(_ line: some StringProtocol, useJokers: Bool = false) {
        guard let (cardsStr, bidStr) = line.splitOnce(separator: " ") else {
            fatalError("missing space")
        }

        let cards = cardsStr.compactMap({
            $0 == "J" && useJokers
            ? CardRank.Joker
            : CardRank(rawValue: $0)
        })

        guard let bid = Int(bidStr),
              cards.count == 5 else {
            fatalError("bad line? \(line)")
        }

        self.bid = bid
        self.cards = cards

        var rankFrequencies = cards.reduce(into: [:]) { h, r in
            h[r, default: 0] += 1
        }
        let jokerCount = rankFrequencies.removeValue(forKey: .Joker) ?? 0
        var frequencies = rankFrequencies
            .values
            .sorted(by: >)

        if frequencies.isEmpty {
            // 5 jokers, crazy!
            frequencies.append(jokerCount)
        } else {
            // always use Jokers as most common card
            frequencies[0] += jokerCount
        }

        self.type = switch frequencies {
        case [5]: .FiveOfAKind
        case [4, 1]: .FourOfAKind
        case [3, 2]: .FullHouse
        case [3, 1, 1]: .ThreeOfAKind
        case [2, 2, 1]: .TwoPair
        case [2, 1, 1, 1]: .OnePair
        case [1, 1, 1, 1, 1]: .HighCard
        default: fatalError("unrecognized HandType: \(cardsStr)")
        }
    }
}

extension CamelCards {
    public init(_ string: String, useJokers: Bool = false) {
        rankedHands = string.lines()
            .map({ CamelCardHand($0, useJokers: useJokers) })
            .sorted(by: <)
    }
}


extension CamelCardHand: Comparable {
    public static func < (lhs: CamelCardHand, rhs: CamelCardHand) -> Bool {
        if lhs.type == rhs.type {
            return lhs.cards < rhs.cards
        } else {
            return lhs.type < rhs.type
        }
    }
}

extension Array: Comparable where Element == CardRank {
    public static func < (lhs: Array<CardRank>, rhs: Array<CardRank>) -> Bool {
        for (l, r) in zip(lhs, rhs) where l != r {
            // first non-equal entry
            return l < r
        }

        // looks like they're equal or not the same length, undefined per problem statement
        return false
    }
}


extension CardRank: Comparable {
    public static func <(_ lhs: CardRank, _ rhs: CardRank) -> Bool {
        // cases are listed highest to lowest, flip the order:
        return allCases.firstIndex(of: lhs)! > allCases.firstIndex(of: rhs)!
    }
}

extension HandType: CaseIterable, Comparable {
    public static func <(_ lhs: HandType, _ rhs: HandType) -> Bool {
        // cases are listed highest to lowest, flip the order:
        return allCases.firstIndex(of: lhs)! > allCases.firstIndex(of: rhs)!
    }
}
