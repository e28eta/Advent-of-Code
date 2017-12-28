import Foundation

public enum InstructionMazeMode {
    case alwaysIncrease, decreaseLargePositiveJumps
}

public struct InstructionMaze: Sequence, CustomStringConvertible {
    public var instructions: [Int]
    public var currentInstruction: Array<Int>.Index
    public var mode: InstructionMazeMode

    public init(instructions: [Int], mode: InstructionMazeMode = .alwaysIncrease) {
        self.instructions = instructions
        self.currentInstruction = self.instructions.startIndex
        self.mode = mode
    }

    public mutating func step() -> Bool {
        guard instructions.indices.contains(currentInstruction) else { return false }
        let offset = instructions[currentInstruction]

        if mode == .decreaseLargePositiveJumps && offset >= 3 {
            instructions[currentInstruction] -= 1
        } else {
            instructions[currentInstruction] += 1
        }
        currentInstruction = currentInstruction.advanced(by: offset)

        return instructions.indices.contains(currentInstruction)
    }

    public func makeIterator() -> AnyIterator<InstructionMaze> {
        var captured: InstructionMaze? = self

        return AnyIterator() {
            let next = captured

            if captured?.step() == false {
                captured = nil
            }

            return next
        }
    }

    public var description: String {
        return instructions.enumerated().map { (i, val) in
            i == currentInstruction ? "(\(val))" : "\(val)"
            }
            .joined(separator: " ")
    }
}

extension Sequence {
    public func count() -> Int {
        return reduce(0) { cnt, _ in cnt + 1 }
    }
}

