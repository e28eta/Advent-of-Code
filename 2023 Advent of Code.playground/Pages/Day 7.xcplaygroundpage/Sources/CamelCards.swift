import Foundation

public enum CardRank: Character, CaseIterable {
    case Ace = "A", King = "K", Queen = "Q", Jack = "J", Ten = "T",
         Nine = "9", Eight = "8", Seven = "7", Six = "6",
         Five = "5", Four = "4", Three = "3", Two = "2"
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

    init(_ line: some StringProtocol) {
        guard let (cardsStr, bidStr) = line.splitOnce(separator: " ") else {
            fatalError("missing space")
        }

        let cards = cardsStr.compactMap(CardRank.init)

        guard let bid = Int(bidStr),
              cards.count == 5 else {
            fatalError("bad line? \(line)")
        }

        self.bid = bid
        self.cards = cards

        let rankFrequencies = cards.reduce(into: [:]) { h, r in
            h[r, default: 0] += 1
        }
            .values
            .sorted(by: >)

        self.type = switch rankFrequencies {
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
    public init(_ string: String) {
        rankedHands = string.lines()
            .map(CamelCardHand.init)
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
