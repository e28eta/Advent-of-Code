import Foundation

public class Player {
    let number: Int
    public var deck: [Int]

    public init?<S: StringProtocol>(_ string: S) {
        let lines = string.lines()
        guard let numberString = lines.first?.replacingOccurrences(of: "Player ", with: "").replacingOccurrences(of: ":", with: ""),
              let number = Int(numberString) else { return nil }

        self.number = number
        self.deck = lines.dropFirst().compactMap(Int.init)
    }
}

class RecursiveCombatResults {
    var memoization: [[Int]: [[Int]: WinningDeck]] = [:]

    enum WinningDeck {
        case first, second

        var inverted: WinningDeck {
            switch self {
            case .first: return .second
            case .second: return .first
            }
        }
    }

    func outcome(of first: [Int], against second: [Int]) -> WinningDeck? {
        return memoization[first]?[second]
    }

    func recordOutcome(of first: [Int], against second: [Int], as winner: WinningDeck) {
        memoization[first, default: [:]][second] = winner
        memoization[second, default: [:]][first] = winner.inverted
    }
}

public struct RecursiveCombat {
    let players: (Player, Player)
    let recursiveCombatResults = RecursiveCombatResults()

    public init?(_ string: String) {
        guard let playerStrings = string.splitOnce(separator: "\n\n"),
              let playerOne = Player(playerStrings.0),
              let playerTwo = Player(playerStrings.1) else { return nil }

        players = (playerOne, playerTwo)
    }

    public func play() -> Int {
        let (_, winningDeck) = playRecursiveGame(of: players.0.deck, against: players.1.deck)

        return zip(winningDeck.reversed(), (1...))
            .map { $0.0 * $0.1 }
            .reduce(0, +)
    }

    func playRecursiveGame(of deckOne: [Int], against deckTwo: [Int]) -> (RecursiveCombatResults.WinningDeck, [Int]) {
        // don't play again if we already know the outcome
        if let previousResult = recursiveCombatResults.outcome(of: deckOne, against: deckTwo) {
            return (previousResult, []) // not going to save the winning deck value, since always tossed
        }

        var previousRounds: [([Int], [Int])] = []
        var decks: ([Int], [Int]) = (deckOne, deckTwo)

        while !decks.0.isEmpty && !decks.1.isEmpty {
            if previousRounds.contains(where: { previous in decks.0 == previous.0 && decks.1 == previous.1 }) {
                // insta-win for player one
                recursiveCombatResults.recordOutcome(of: deckOne,
                                                     against: deckTwo,
                                                     as: .first)
                return (.first, decks.0)
            }
            previousRounds.append(decks)

            let cards = (decks.0.removeFirst(), decks.1.removeFirst())

            let roundWinner: RecursiveCombatResults.WinningDeck
            if cards.0 <= decks.0.count && cards.1 <= decks.1.count {
                (roundWinner, _) = playRecursiveGame(of: Array(decks.0.prefix(cards.0)), against: Array(decks.1.prefix(cards.1)))
            } else {
                roundWinner = cards.0 > cards.1 ? .first : .second
            }

            if roundWinner == .first {
                decks.0.append(cards.0)
                decks.0.append(cards.1)
            } else {
                decks.1.append(cards.1)
                decks.1.append(cards.0)
            }
        }

        let gameWinner = decks.0.isEmpty ? (RecursiveCombatResults.WinningDeck.second, decks.1) : (.first, decks.0)
        recursiveCombatResults.recordOutcome(of: deckOne,
                                             against: deckTwo,
                                             as: gameWinner.0)
        return gameWinner
    }
}
