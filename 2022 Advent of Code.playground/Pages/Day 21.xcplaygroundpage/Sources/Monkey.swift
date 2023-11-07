import Foundation

enum Job {
    case literal(Int)
    case evaluate(Operator, Monkey.Identifier, Monkey.Identifier)

    enum Operator {
        case add, subtract, multiply, divide
    }
}

public struct Monkey {
    public typealias Identifier = String

    let identifier: Identifier
    let job: Job
}

public struct MonkeyTroop {
    /// identifier to Monkey object
    let monkeys: [Monkey.Identifier: Monkey]

    /// identifier to already-computed value, if the calc has been done
    var monkeyValue: [Monkey.Identifier: Int] = [:]

    public init(_ string: String) {
        let monkeyArray = string.lines().compactMap(Monkey.init)

        monkeys = monkeyArray.reduce(into: [:]) {
            $0[$1.identifier] = $1
        }
    }

    mutating public func value(for monkeyId: Monkey.Identifier) -> Int {
        if let value = monkeyValue[monkeyId] {
            return value
        }

        guard let monkey = monkeys[monkeyId] else {
            fatalError("Unknown monkey \(monkeyId)")
        }

        let result: Int
        switch monkey.job {
        case .literal(let value):
            result = value
        case let .evaluate(op, leftId, rightId):
            result = op(value(for: leftId),
                        value(for: rightId))
        }

        monkeyValue[monkeyId] = result
        return result
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

    func callAsFunction(_ left: Int, _ right: Int) -> Int {
        switch self {
        case .add: return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide: return left / right
        }
    }
}
