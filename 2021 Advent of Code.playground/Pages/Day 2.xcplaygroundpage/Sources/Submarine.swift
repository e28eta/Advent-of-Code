import Foundation

public enum Command {
    case forward(Int)
    case down(Int)
    case up(Int)

    public init?(_ line: String) {
        guard let (command, amountString) = line.splitOnce(separator: " "),
              let amount = Int(amountString) else {
            return nil
        }

        switch command {
        case "forward":
            self = .forward(amount)
        case "down":
            self = .down(amount)
        case "up":
            self = .up(amount)
        default:
            return nil
        }
    }

    static public func parse(_ string: String) -> [Command] {
        return string.lines().compactMap(Command.init)
    }
}

public struct Position {
    public init() {}

    public func part1(_ commands: [Command]) -> Int {
        var horizontal = 0
        var depth = 0

        for command in commands {
            switch command {
            case .forward(let amount):
                horizontal += amount
            case .down(let amount):
                depth += amount
            case .up(let amount):
                depth -= amount
            }
        }

        return horizontal * depth
    }

    public func part2(_ commands: [Command]) -> Int {
        var horizontal = 0
        var depth = 0
        var aim = 0

        for command in commands {
            switch command {
            case .forward(let amount):
                horizontal += amount
                depth += (aim * amount)
            case .down(let amount):
                aim += amount
            case .up(let amount):
                aim -= amount
            }
        }

        return horizontal * depth
    }
}
