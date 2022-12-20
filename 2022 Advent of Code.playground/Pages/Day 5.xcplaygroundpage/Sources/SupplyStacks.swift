import Foundation
import RegexBuilder

public struct Instruction {
    public let source: Int
    public let destination: Int
    public let count: Int

    public init?<SP: StringProtocol>(_ line: SP) where SP.SubSequence == Substring {
        let regex = /move (?<count>\d+) from (?<source>\d+) to (?<destination>\d+)/
        guard let result = line.wholeMatch(of: regex),
              let count = Int(result.count),
              let source = Int(result.source),
              let destination = Int(result.destination) else {
            return nil
        }

        self.count = count
        self.source = source
        self.destination = destination
    }
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        return "move \(count) from \(source) to \(destination)"
    }
}

public struct Crate {
    let contents: Character

    init?<SP: StringProtocol>(_ string: SP) where SP.SubSequence == Substring {
        guard let contents = string.firstMatch(of: /[A-Z]/)?.first else { return nil }
        self.contents = contents
    }

    public static func crates(from line: String) -> [Crate?] {
        return sequence(state: line[...]) { remaining in
            defer { remaining = remaining.dropFirst(4) }
            let result = remaining.prefix(3)
            // turn empty string into nil to end the sequence
            return result.isEmpty ? nil : result
        }.map(Crate.init)
    }
}

extension Crate: CustomStringConvertible {
    public var description: String {
        return "[\(contents)]"
    }
}

public struct SupplyStacks {
    var stacks: [Int: [Crate]]

    public init?(_ input: some StringProtocol) {
        var reversed = input.lines().reversed().makeIterator()
        guard let stackNumbers = reversed.next() else { return nil }

        let stackNumRegex = Regex {
            TryCapture { OneOrMore(.digit) } transform: { Int($0) }
        }

        let columns = stackNumbers.matches(of: stackNumRegex).map(\.output.1)

        stacks = reversed.reduce(into: [:]) { dict, line in
            for case let (idx, .some(crate)) in Crate.crates(from: line).enumerated() {

                let col = columns[idx]
                dict[col, default: []].append(crate)
            }
        }
    }

    public mutating func apply(_ instruction: Instruction, reversingCrates: Bool = true) {
        guard stacks[instruction.source] != nil,
              stacks[instruction.destination] != nil else {
            return
        }

        var moved: any Sequence<Crate> = stacks[instruction.source]!.suffix(instruction.count)
        if (reversingCrates) {
            moved = moved.reversed()
        }
        stacks[instruction.source]!.removeLast(instruction.count)
        stacks[instruction.destination]!.append(contentsOf: moved)
    }

    public var topCrates: String {
        let characters: [Character] = stacks.keys
            .sorted()
            .compactMap { key in
                stacks[key]!.last?.contents
            }

        return String(characters)
    }
}

extension SupplyStacks: CustomStringConvertible {
    public var description: String {
        stacks.keys
            .sorted()
            .map { key in
                "\(key): \(stacks[key]!.map(\.description).joined(separator: " "))"
            }
            .joined(separator: "\n")
    }
}
