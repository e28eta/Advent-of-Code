import Foundation

enum Job {
    case unknown
    case literal(Int)
    case evaluate(Operator, Monkey.Identifier, Monkey.Identifier)

    enum Operator {
        case add, subtract, multiply, divide, equality
    }
}

public struct Monkey {
    public typealias Identifier = String

    let identifier: Identifier
    let job: Job
}

public struct MonkeyTroop {
    public static let RootId = "root"
    static let HumanId = "humn"
    /// identifier to Monkey object
    var monkeys: [Monkey.Identifier: Monkey]

    public init(_ string: String) {
        let monkeyArray = string.lines().compactMap(Monkey.init)

        monkeys = monkeyArray.reduce(into: [:]) {
            $0[$1.identifier] = $1
        }
    }

    mutating public func fixMistranslation() {
        guard let previousRoot = monkeys[MonkeyTroop.RootId],
              case let .evaluate(_, leftRoot, rightRoot) = previousRoot.job else {
            fatalError("root missing or Job isn't to evaluate")
        }

        monkeys[MonkeyTroop.RootId] = Monkey(identifier: MonkeyTroop.RootId,
                                             job: .evaluate(.equality, leftRoot, rightRoot))
        monkeys[MonkeyTroop.HumanId] = Monkey(identifier: MonkeyTroop.HumanId,
                                              job: .unknown)
    }

    public func value(for monkeyId: Monkey.Identifier) -> Int {
        guard case .value(let value) = result(for: monkeyId) else {
            fatalError("result was not a value!")
        }

        return value
    }

    func result(for monkeyId: Monkey.Identifier) -> Job.Operator.Result {
        guard let monkey = monkeys[monkeyId] else {
            fatalError("Unknown monkey \(monkeyId)")
        }

        switch monkey.job {
        case .unknown:
            return .unknown({ $0 })
        case .literal(let value):
            return .value(value)
        case let .evaluate(op, leftId, rightId):
            return op(result(for: leftId),
                      result(for: rightId))
        }
    }
}


extension Monkey {
    init?(_ line: String) {
        guard let (id, jobString) = line.splitOnce(separator: ": "),
              let job = Job(jobString) else {
            return nil
        }

        identifier = String(id)
        self.job = job
    }
}

extension Job {
    init?(_ jobString: some StringProtocol) {
        let jobComponents = jobString.split(separator: " ")

        if jobComponents.count == 1,
           let literal = Int(jobComponents[0]) {
            self = .literal(literal)
        } else if jobComponents.count == 3,
                  let op = Operator(jobComponents[1]) {
            self = .evaluate(op,
                             String(jobComponents[0]),
                             String(jobComponents[2]))
        } else {
            return nil
        }
    }
}

extension Job.Operator {
    init?(_ string: some StringProtocol) {
        switch string {
        case "+": self = .add
        case "-": self = .subtract
        case "*": self = .multiply
        case "/": self = .divide
        default:
            print("error, unhandled operator \(string)")
            return nil
        }
    }

    enum Result {
        /// function result is fully specified
        case value(Int)

        /// Result has `humn` in it. Build a function that takes the desired result
        /// and returns the value that `humn` should resolve to
        case unknown((Int) -> Int)
    }

    func callAsFunction(_ left: Result, _ right: Result) -> Result {
        switch (self, left, right) {
        case (_, .unknown, .unknown):
            fatalError("should never have two unknown results in the tree")
        case let (.add, .value(left), .value(right)):
            return .value(left + right)
        case let (.add, .value(value), .unknown(fx)),
            let (.add, .unknown(fx), .value(value)):
            // result = value + unknown
            return .unknown({ result in
                fx(result - value)
            })

        case let (.subtract, .value(left), .value(right)):
            return .value(left - right)
        case let (.subtract, .value(value), .unknown(fx)):
            // result = value - unknown
            return .unknown({ result in
                fx(value - result)
            })
        case let (.subtract, .unknown(fx), .value(value)):
            // result = unknown - value
            return .unknown({ result in
                fx(result + value)
            })

        case let (.multiply, .value(left), .value(right)):
            return .value(left * right)
        case let (.multiply, .value(value), .unknown(fx)),
            let (.multiply, .unknown(fx), .value(value)):
            // result = value * unknown
            return .unknown({ result in
                fx(result / value)
            })

        case let (.divide, .value(left), .value(right)):
            return .value(left / right)
        case let (.divide, .value(value), .unknown(fx)):
            // result = value / unknown
            return .unknown({ result in
                fx(value / result)
            })
        case let (.divide, .unknown(fx), .value(value)):
            // result = unknown / value
            return .unknown({ result in
                fx(result * value)
            })

        case let (.equality, .unknown(fx), .value(value)),
            let (.equality, .value(value), .unknown(fx)):
            // we can solve!
            return .value(fx(value))
        case (.equality, .value, .value):
            fatalError("equality should not have two values")
        }
    }
}
