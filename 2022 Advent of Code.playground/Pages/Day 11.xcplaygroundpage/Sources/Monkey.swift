import Foundation
import RegexBuilder


public typealias Item = Int

public class MonkeyBusiness {
    let debug = false
    public private(set) var monkeys: [Monkey]
    var roundNumber = 1
    let worryLevelManagementFactor: Int

    public init(_ string: String) {
        monkeys = string.matches(of: Monkey.MatchingRegex).map(Monkey.init)

        worryLevelManagementFactor = lcm(monkeys.map(\.test.testValue))
    }

    public func part1() -> Int {
        return calculate(numRounds: 20, scaleByOneThird: true)
    }

    public func part2() -> Int {
        return calculate(numRounds: 10_000, scaleByOneThird: false)
    }

    func calculate(numRounds: Int, scaleByOneThird: Bool) -> Int {
        for _ in (0 ..< numRounds) {
            round(scaleByOneThird: scaleByOneThird)
        }

        let counts = inspectionCounts()

        if debug {
            for (idx, count) in counts.enumerated() {
                print("Monkey \(idx) inspected items \(count) times.")
            }
        }

        return counts.sorted().suffix(2).reduce(1, *)
    }

    func round(scaleByOneThird: Bool) {
        for idx in monkeys.indices {
            turn(idx, scaleByOneThird: scaleByOneThird)
        }

        if debug &&
            ((scaleByOneThird && (roundNumber < 10 || roundNumber % 5 == 0 ))
             || (roundNumber % 1_000 == 0)) {
            print("After round \(roundNumber), the monkeys are holding items with these worry levels:")
            for monkey in monkeys {
                print("Monkey \(monkey.id):", monkey.items)
            }
            print()
        }

        roundNumber += 1
    }

    func turn(_ idx: Int, scaleByOneThird: Bool) {
        let currentMonkey = monkeys[idx]

        for var item in currentMonkey.items {
            item = currentMonkey.operation(item)
            if (scaleByOneThird) {
                item /= 3
            }
            item %= worryLevelManagementFactor
            let destination = currentMonkey.test(item)
            monkeys[destination].items.append(item)
        }
        
        currentMonkey.inspectionCount += currentMonkey.items.count
        currentMonkey.items = []

        monkeys[idx] = currentMonkey
    }

    public func inspectionCounts() -> [Int] {
        return monkeys.map(\.inspectionCount)
    }
}

public class Monkey {
    public let id: Int
    public var items: [Item]
    public let operation: Monkey.Operation
    public let test: Monkey.Test
    public var inspectionCount: Int = 0

    init(_ match: Regex<(Substring, Int, Array<Int>, Monkey.Operation, Int, Int, Int)>.Match) {
        id = match[Monkey.MonkeyIdRef]
        items = match[Monkey.StartingItemsRef]
        operation = match[Monkey.Operation.OperationRef]
        test = Monkey.Test(testValue: match[Monkey.Test.TestDivisorRef],
                           trueDestination: match[Monkey.Test.TrueTargetRef],
                           falseDestination: match[Monkey.Test.FalseTargetRef])

        guard id != test.trueDestination && id != test.falseDestination else {
            fatalError("assumption that monkey never throws to itself is broken")
        }
    }
}

// MARK: Operation

extension Monkey {
    public struct Operation {
        let left: Operand, op: Operator, right: Operand

        public init(_ string: some StringProtocol) {
            let trimmed = string.trimmingCharacters(in: .whitespaces)
            guard let (left, suffix) = trimmed.splitOnce(separator: " "),
                  let (op, right) = suffix.splitOnce(separator: " ")
            else {
                fatalError("malformed operation: \(string)")
            }

            self.left = Operand(left)
            self.op = Operator(op)
            self.right = Operand(right)
        }

        public func callAsFunction(_ value: Int) -> Int {
            op(left.value ?? value, right.value ?? value)
        }

        enum Operator {
            case add, multiply

            init(_ string: some StringProtocol) {
                switch string {
                case "+": self = .add
                case "*": self = .multiply
                default: fatalError("unhandled operator \(string)")
                }
            }

            func callAsFunction(_ left: Int, _ right: Int) -> Int {
                switch self {
                case .add: return left + right
                case .multiply: return left * right
                }
            }
        }

        enum Operand {
            case oldValue, literal(Int)

            init( _ string: some StringProtocol) {
                if string == "old" {
                    self = .oldValue
                } else if let value = Int(string) {
                    self = .literal(value)
                } else {
                    fatalError("unhandled operand \(string)")
                }
            }

            var value: Int? {
                if case .literal(let int) = self {
                    return int
                } else {
                    return nil
                }
            }
        }
    }
}

// MARK: Test

extension Monkey {
    public struct Test {
        public let testValue: Int
        public let trueDestination: Int
        public let falseDestination: Int

        init(testValue: Int, trueDestination: Int, falseDestination: Int) {
            self.testValue = testValue
            self.trueDestination = trueDestination
            self.falseDestination = falseDestination
        }

        public func callAsFunction(_ value: Int) -> Int {
            return (value % testValue == 0) ? trueDestination : falseDestination
        }
    }
}

// MARK: Regex
let EnglishLocale = Locale(identifier: "en-US")

public extension Monkey {
    static let MonkeyIdRef = Reference<Int>()
    static let StartingItemsRef = Reference<[Int]>()

    static let MatchingRegex = Regex {
        Anchor.startOfLine
        "Monkey "
        Capture(.localizedInteger(locale: EnglishLocale), as: MonkeyIdRef)
        ":"
        One(.newlineSequence)

        StartingItemsRegex
        One(.newlineSequence)

        Monkey.Operation.MatchingRegex
        One(.newlineSequence)

        Monkey.Test.MatchingRegex
        Optionally(.newlineSequence)
    }

    static let StartingItemsRegex = Regex {
        Anchor.startOfLine
        OneOrMore(.whitespace)
        "Starting items: "
        Capture(as: StartingItemsRef) {
            ZeroOrMore {
                One(.localizedInteger(locale: EnglishLocale))
                ", "
            }
            One(.localizedInteger(locale: EnglishLocale))
        } transform: {
            $0.components(separatedBy: ", ").compactMap(Int.init)
        }
        Anchor.endOfLine
    }
}

public extension Monkey.Operation {
    static let OperationRef = Reference<Monkey.Operation>()
    static let MatchingRegex = Regex {
        Anchor.startOfLine
        OneOrMore(.whitespace)
        "Operation: new = "
        Capture(as: OperationRef) {
            Operand.MatchingRegex
            One(.whitespace)
            Operator.MatchingRegex
            One(.whitespace)
            Operand.MatchingRegex
        } transform: {
            Monkey.Operation($0)
        }
        Anchor.endOfLine
    }
}

extension Monkey.Operation.Operator {
    static let MatchingRegex = Regex {
        ChoiceOf {
            "+"
            "*"
        }
    }
}

extension Monkey.Operation.Operand {
    static let MatchingRegex = Regex {
        ChoiceOf {
            "old"
            One(.localizedInteger(locale: EnglishLocale))
        }
    }
}

public extension Monkey.Test {
    static let TestDivisorRef = Reference<Int>()
    static let TrueTargetRef = Reference<Int>()
    static let FalseTargetRef = Reference<Int>()

    static let MatchingRegex = Regex {
        Anchor.startOfLine
        OneOrMore(.whitespace)
        "Test: divisible by "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: TestDivisorRef)
        One(.newlineSequence)
        OneOrMore(.whitespace)
        "If true: throw to monkey "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: TrueTargetRef)
        One(.newlineSequence)
        OneOrMore(.whitespace)
        "If false: throw to monkey "
        Capture(.localizedInteger(locale: EnglishLocale),
                as: FalseTargetRef)
        Anchor.endOfLine
    }
}

// MARK: CustomStringConvertible

extension Monkey.Operation: CustomStringConvertible {
    public var description: String {
        return "\(left) \(op) \(right)"
    }
}

extension Monkey.Operation.Operator: CustomStringConvertible {
    public var description: String {
        switch self {
        case .add: return "+"
        case.multiply: return "*"
        }
    }
}

extension Monkey.Operation.Operand: CustomStringConvertible {
    public var description: String {
        switch self {
        case .oldValue:
            return "old"
        case .literal(let int):
            return String(int)
        }
    }
}

extension Monkey.Test: CustomStringConvertible {
    public var description: String {
        return "if % \(testValue) then \(trueDestination) else \(falseDestination)"
    }
}
