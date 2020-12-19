//: [Previous](@previous)

import Foundation

/**
 --- Day 18: Operation Order ---

 As you look out the window and notice a heavily-forested continent slowly appear over the horizon, you are interrupted by the child sitting next to you. They're curious if you could help them with their math homework.

 Unfortunately, it seems like this "math" [follows different rules](https://www.youtube.com/watch?v=3QtRK7Y2pPU&t=15) than you remember.

 The homework (your puzzle input) consists of a series of expressions that consist of addition (`+`), multiplication (`*`), and parentheses (`(...)`). Just like normal math, parentheses indicate that the expression inside must be evaluated before it can be used by the surrounding expression. Addition still finds the sum of the numbers on both sides of the operator, and multiplication still finds the product.

 However, the rules of **operator precedence** have changed. Rather than evaluating multiplication before addition, the operators have the **same precedence**, and are evaluated left-to-right regardless of the order in which they appear.

 For example, the steps to evaluate the expression `1 + 2 * 3 + 4 * 5 + 6` are as follows:

 ```
 1 + 2 * 3 + 4 * 5 + 6
 3   * 3 + 4 * 5 + 6
 9   + 4 * 5 + 6
 13   * 5 + 6
 65   + 6
 71
 ```

 Parentheses can override this order; for example, here is what happens if parentheses are added to form `1 + (2 * 3) + (4 * (5 + 6))`:

 ```
 1 + (2 * 3) + (4 * (5 + 6))
 1 +    6    + (4 * (5 + 6))
 7      + (4 * (5 + 6))
 7      + (4 *   11   )
 7      +     44
 51
 ```

 Here are a few more examples:

 - `2 * 3 + (4 * 5)` becomes `26`.
 - `5 + (8 * 3 + 9 + 3 * 4 * 3)` becomes `437`.
 - `5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))` becomes `12240`.
 - `((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2` becomes `13632`.

 Before you can help with the homework, you need to understand it yourself. **Evaluate the expression on each line of the homework; what is the sum of the resulting values?**
 */

enum Token: CustomStringConvertible, Equatable {
    case number(Int)
    case plus, multiply, leftParen, rightParen

    static func tokens(from string: String) -> [Token] {
        let validCharacters: CharacterSet = {
            var charSet = CharacterSet.decimalDigits
            charSet.insert(charactersIn: "+*()")
            return charSet
        }()
        let digits = CharacterSet.decimalDigits

        // add empty string as hack to finish lexing the last number...
        return (string + " ").unicodeScalars.reduce(([], nil)) { (r, c) -> ([Token], String?) in
            var (tokens, partialNumber) = r

            if !digits.contains(c), let value = partialNumber.flatMap(Int.init) {
                // end of the number
                tokens.append(.number(value))
                partialNumber = nil
            }

            guard validCharacters.contains(c) else {
                return (tokens, nil)
            }

            switch c {
            case "+":
                tokens.append(.plus)
            case "*":
                tokens.append(.multiply)
            case "(":
                tokens.append(.leftParen)
            case ")":
                tokens.append(.rightParen)
            default:
                partialNumber = (partialNumber ?? "") + String(c)
            }

            return (tokens, partialNumber)
        }.0
    }

    var description: String {
        switch self {
        case .plus: return "+"
        case .multiply: return "*"
        case .leftParen: return "("
        case .rightParen: return ")"
        case .number(let value): return String(value)
        }
    }

    static func ==(_ lhs: Token, _ rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.plus, plus),
             (.multiply, .multiply),
             (.leftParen, .leftParen),
             (.rightParen, .rightParen):
            return true
        case let (.number(left), .number(right)):
            return left == right
        default:
            return false
        }
    }
}

//MARK: Parsing

/*
 hand-rolled recursive descent LL(1) parser, I think
 */

indirect enum Part1Expression: CustomStringConvertible {
    case factor(Part1Factor, Part1ExpressionPrime?)

    static func topLevelParse(from tokens: [Token]) -> Part1Expression? {
        do {
            let (expression, remaining) = try parse(from: tokens[tokens.startIndex..<tokens.endIndex])
            guard remaining.count == 0 else {
                print("unconsumed tokens!", remaining)
                return nil
            }
            return expression
        } catch {
            print("error parsing tokens", error)
            return nil
        }
    }

    static func parse<T: Collection>(from tokens: T) throws -> (Part1Expression, T) where T.Element == Token, T.SubSequence == T {
        let (factor, remaining) = try Part1Factor.parse(from: tokens)
        let (exprPrime, final) = try Part1ExpressionPrime.parse(from: remaining)

        return (.factor(factor, exprPrime), final)
    }

    func evaluate() -> Int {
        switch self {
        case .factor(let factor, .none):
            return factor.evaluate()
        case .factor(let factor, .some(let exprPrime)):
            return exprPrime.evaluate(factor.evaluate())
        }
    }

    var description: String {
        switch self {
        case .factor(let factor, .some(let exprPrime)):
            return factor.description + " " + exprPrime.description
        case .factor(let factor, .none):
            return factor.description
        }
    }
}

indirect enum Part1ExpressionPrime: CustomStringConvertible {
    case addition(Part1Factor, Part1ExpressionPrime?)
    case multiplication(Part1Factor, Part1ExpressionPrime?)

    static func parse<T: Collection>(from tokens: T) throws -> (Part1ExpressionPrime?, T) where T.Element == Token, T.SubSequence == T {
        guard let next = tokens.first, next == .plus || next == .multiply else {
            return (nil, tokens)
        }
        let (factor, remaining) = try Part1Factor.parse(from: tokens.dropFirst())
        let (exprPrime, final) = try Part1ExpressionPrime.parse(from: remaining)

        switch next {
        case .plus:
            return (.addition(factor, exprPrime), final)
        case .multiply:
            return (.multiplication(factor, exprPrime), final)
        default:
            fatalError()
        }
    }

    var description: String {
        switch self {
        case let .addition(factor, .some(exprPrime)):
            return "+ \(factor.description) \(exprPrime.description)"
        case let .addition(factor, .none):
            return "+ \(factor.description)"
        case let .multiplication(factor, .some(exprPrime)):
            return "* \(factor.description) \(exprPrime.description)"
        case let .multiplication(factor, .none):
            return "* \(factor.description)"
        }
    }

    func evaluate(_ lhs: Int) -> Int {
        let intermediate: Int
        switch self {
        case .addition(let factor, _):
            intermediate = lhs + factor.evaluate()
        case .multiplication(let factor, _):
            intermediate = lhs * factor.evaluate()
        }

        switch self {
        case .addition(_, .some(let exprPrime)),
             .multiplication(_, .some(let exprPrime)):
            return exprPrime.evaluate(intermediate)
        case .addition(_, .none), .multiplication(_, .none):
            return intermediate
        }
    }
}

enum ParseError: Error {
    case literalNotFound
    case unbalancedParens
}

indirect enum Part1Factor: CustomStringConvertible {
    case literal(Int)
    case parenthetical(Part1Expression)

    static func parse<T: Collection>(from tokens: T) throws -> (Part1Factor, T) where T.Element == Token, T.SubSequence == T {
        guard let next = tokens.first else {
            throw ParseError.literalNotFound
        }

        switch next {
        case let .number(value):
            return (.literal(value), tokens.dropFirst())
        case .leftParen:
            let (expression, remaining) = try Part1Expression.parse(from: tokens.dropFirst())
            guard remaining.first == .rightParen else {
                throw ParseError.unbalancedParens
            }
            return (.parenthetical(expression), remaining.dropFirst())
        default:
            throw ParseError.literalNotFound
        }
    }

    var description: String {
        switch self {
        case .literal(let value):
            return value.description
        case .parenthetical(let expr):
            return "( \(expr.description) )"
        }
    }

    func evaluate() -> Int {
        switch self {
        case .literal(let value):
            return value
        case .parenthetical(let expr):
            return expr.evaluate()
        }
    }
}

let exampleInput = [
    ("1 + 2 * 3 + 4 * 5 + 6", 71),
    ("1 + (2 * 3) + (4 * (5 + 6))", 51),
    ("2 * 3 + (4 * 5)", 26),
    ("5 + (8 * 3 + 9 + 3 * 4 * 3)", 437),
    ("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))", 12240),
    ("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2", 13632),
]

verify(exampleInput) { s in
    Part1Expression.topLevelParse(from: Token.tokens(from: s))?.evaluate() ?? -1
}

let input = try readResourceFile("input.txt").lines().map(Token.tokens)
let partOne = input
    .compactMap(Part1Expression.topLevelParse)
    .reduce(0) { $0 + $1.evaluate() }

assertEqual(partOne, 11076907812171)

/**
 --- Part Two ---

 You manage to answer the child's questions and they finish part 1 of their homework, but get stuck when they reach the next section: **advanced** math.

 Now, addition and multiplication have **different** precedence levels, but they're not the ones you're familiar with. Instead, addition is evaluated **before** multiplication.

 For example, the steps to evaluate the expression `1 + 2 * 3 + 4 * 5 + 6` are now as follows:

 ```
 1 + 2 * 3 + 4 * 5 + 6
 3   * 3 + 4 * 5 + 6
 3   *   7   * 5 + 6
 3   *   7   *  11
 21       *  11
        231
 ```

 Here are the other examples from above:

 - `1 + (2 * 3) + (4 * (5 + 6))` still becomes `51`.
 - `2 * 3 + (4 * 5)` becomes `46`.
 - `5 + (8 * 3 + 9 + 3 * 4 * 3)` becomes `1445`.
 - `5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))` becomes `669060`.
 - `((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2` becomes `23340`.

 \**What do you get if you add up the results of evaluating the homework problems using these new rules?**
 */

indirect enum Part2Expression: CustomStringConvertible {
    case term(Part2Term, Part2ExpressionPrime?)

    static func topLevelParse(from tokens: [Token]) -> Part2Expression? {
        do {
            let (expression, remaining) = try parse(from: tokens[tokens.startIndex..<tokens.endIndex])
            guard remaining.count == 0 else {
                print("unconsumed tokens!", remaining)
                return nil
            }
            return expression
        } catch {
            print("error parsing tokens", error)
            return nil
        }
    }

    static func parse<T: Collection>(from tokens: T) throws -> (Part2Expression, T) where T.Element == Token, T.SubSequence == T {
        let (term, remaining) = try Part2Term.parse(from: tokens)
        let (exprPrime, final) = try Part2ExpressionPrime.parse(from: remaining)

        return (.term(term, exprPrime), final)
    }

    func evaluate() -> Int {
        switch self {
        case .term(let term, .none):
            return term.evaluate()
        case .term(let term, .some(let exprPrime)):
            return exprPrime.evaluate(term.evaluate())
        }
    }

    var description: String {
        switch self {
        case .term(let term, .none):
            return term.description
        case .term(let term, .some(let exprPrime)):
            return term.description + " " + exprPrime.description
        }
    }
}

indirect enum Part2ExpressionPrime: CustomStringConvertible {
    case multiplication(Part2Term, Part2ExpressionPrime?)

    static func parse<T: Collection>(from tokens: T) throws -> (Part2ExpressionPrime?, T) where T.Element == Token, T.SubSequence == T {
        guard let next = tokens.first, next == .multiply else {
            return (nil, tokens)
        }
        let (term, remaining) = try Part2Term.parse(from: tokens.dropFirst())
        let (exprPrime, final) = try Part2ExpressionPrime.parse(from: remaining)

        return (.multiplication(term, exprPrime), final)
    }

    var description: String {
        switch self {
        case let .multiplication(factor, .some(exprPrime)):
            return "* \(factor.description) \(exprPrime.description)"
        case let .multiplication(factor, .none):
            return "* \(factor.description)"
        }
    }

    func evaluate(_ lhs: Int) -> Int {
        switch self {
        case .multiplication(let factor, .none):
            return lhs * factor.evaluate()
        case .multiplication(let factor, .some(let exprPrime)):
            return exprPrime.evaluate(lhs * factor.evaluate())
        }
    }
}

indirect enum Part2Term: CustomStringConvertible {
    case factor(Part2Factor, Part2TermPrime?)

    static func parse<T: Collection>(from tokens: T) throws -> (Part2Term, T) where T.Element == Token, T.SubSequence == T {
        let (factor, remaining) = try Part2Factor.parse(from: tokens)
        let (termPrime, final) = try Part2TermPrime.parse(from: remaining)

        return (.factor(factor, termPrime), final)
    }

    func evaluate() -> Int {
        switch self {
        case .factor(let factor, .none):
            return factor.evaluate()
        case .factor(let factor, .some(let termPrime)):
            return termPrime.evaluate(factor.evaluate())
        }
    }

    var description: String {
        switch self {
        case .factor(let factor, .none):
            return factor.description
        case .factor(let factor, .some(let termPrime)):
            return factor.description + " " + termPrime.description
        }
    }}

indirect enum Part2TermPrime: CustomStringConvertible {
    case addition(Part2Factor, Part2TermPrime?)

    static func parse<T: Collection>(from tokens: T) throws -> (Part2TermPrime?, T) where T.Element == Token, T.SubSequence == T {
        guard let next = tokens.first, next == .plus else {
            return (nil, tokens)
        }
        let (factor, remaining) = try Part2Factor.parse(from: tokens.dropFirst())
        let (termPrime, final) = try Part2TermPrime.parse(from: remaining)

        return (.addition(factor, termPrime), final)
    }


    var description: String {
        switch self {
        case let .addition(factor, .some(termPrime)):
            return "+ \(factor.description) \(termPrime.description)"
        case let .addition(term, .none):
            return "+ \(term.description)"

        }
    }

    func evaluate(_ lhs: Int) -> Int {
        switch self {
        case .addition(let factor, .none):
            return lhs + factor.evaluate()
        case .addition(let factor, .some(let termPrime)):
            return termPrime.evaluate(lhs + factor.evaluate())
        }
    }
}

indirect enum Part2Factor: CustomStringConvertible {
    case literal(Int)
    case parenthetical(Part2Expression)

    static func parse<T: Collection>(from tokens: T) throws -> (Part2Factor, T) where T.Element == Token, T.SubSequence == T {
        guard let next = tokens.first else {
            throw ParseError.literalNotFound
        }

        switch next {
        case let .number(value):
            return (.literal(value), tokens.dropFirst())
        case .leftParen:
            let (expression, remaining) = try Part2Expression.parse(from: tokens.dropFirst())
            guard remaining.first == .rightParen else {
                throw ParseError.unbalancedParens
            }
            return (.parenthetical(expression), remaining.dropFirst())
        default:
            throw ParseError.literalNotFound
        }
    }

    var description: String {
        switch self {
        case .literal(let value):
            return value.description
        case .parenthetical(let expr):
            return "( \(expr.description) )"
        }
    }

    func evaluate() -> Int {
        switch self {
        case .literal(let value):
            return value
        case .parenthetical(let expr):
            return expr.evaluate()
        }
    }
}

let examplePartTwo = [
    ("1 + 2 * 3 + 4 * 5 + 6", 231),
    ("1 + (2 * 3) + (4 * (5 + 6))", 51),
    ("2 * 3 + (4 * 5)", 46),
    ("5 + (8 * 3 + 9 + 3 * 4 * 3)", 1445),
    ("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))", 669060),
    ("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2", 23340),
]

verify(examplePartTwo) { s in
    Part2Expression.topLevelParse(from: Token.tokens(from: s))?.evaluate() ?? -1
}

let partTwo = input
    .compactMap(Part2Expression.topLevelParse)
    .reduce(0) { $0 + $1.evaluate() }

assertEqual(partTwo, 283729053022731)

//: [Next](@next)
