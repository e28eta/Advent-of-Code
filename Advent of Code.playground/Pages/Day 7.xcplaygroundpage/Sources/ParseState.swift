import Foundation

public struct ParseState {
    enum BracketState { case Inside, Outside }
    public enum TLSState {
        case NoABBAYet, ABBAOutside, ABBAInside

        public var supportsTLS: Bool {
            switch self {
            case .NoABBAYet, .ABBAInside: return false
            case .ABBAOutside: return true
            }
        }
    }

    var first: Character?, second: Character?, third: Character?, fourth: Character?
    var bracketState: BracketState = .Outside
    public var tlsState: TLSState = .NoABBAYet

    public init() {}

    public func handlingCharacter(_ char: Character) -> ParseState {
        var state = self

        switch char {
        case "[":
            state.clearCharacters()
            state.bracketState = .Inside
        case "]":
            state.clearCharacters()
            state.bracketState = .Outside
        default:
            state.first = second
            state.second = third
            state.third = fourth
            state.fourth = char
            if let first = state.first,
                let second = state.second,
                let third = state.third,
                let fourth = state.fourth, first == fourth && second == third && first != second {
                // found an ABBA
                if bracketState == .Inside {
                    state.tlsState = .ABBAInside
                } else if tlsState != .ABBAInside {
                    state.tlsState = .ABBAOutside
                }
            }
        }

        return state
    }

    mutating func clearCharacters() {
        first = nil
        second = nil
        third = nil
        fourth = nil
    }
    
}
