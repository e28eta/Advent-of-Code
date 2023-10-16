import Foundation

public enum Instruction: CustomStringConvertible {
    case noop
    case addx(Int)

    public init?(_ string: some StringProtocol) {
        if string == "noop" {
            self = .noop
        } else if let (instr, val) = string.splitOnce(separator: " "),
                  instr == "addx",
                  let intVal = Int(val) {
            self = .addx(intVal)
        } else {
            return nil
        }
    }

    public var description: String {
        switch self {
        case .noop: return "noop"
        case .addx(let value): return "addx \(value)"
        }
    }
}

public struct CPU {
    public private(set) var register: Int = 1
    public private(set) var cycle: Int = 1

    public init() {}

    public mutating func apply(instruction: Instruction) {
        switch instruction {
        case .noop:
            cycle += 1
        case .addx(let value):
            cycle += 2
            register += value
        }
    }
}

public struct Program {
    public let instructions: [Instruction]

    public init(code: String) {
        instructions = code.lines().compactMap(Instruction.init)
    }
}

public class HandheldDevice {
    let program: Program

    public init(code: String) {
        program = Program(code: code)
    }

    public func part1() -> Int {
        var cpu = CPU()

        // just save them all, and then search for simplicty
        let registerValues: [(Int, Int)] = program.instructions.map { instruction in
            defer { cpu.apply(instruction: instruction) }
            return (cpu.cycle, cpu.register)
        } + [(cpu.cycle, cpu.register)]

        let targetCycles = [20, 60, 100, 140, 180, 220]

        return targetCycles.map { cycle in
            HandheldDevice.findRegisterValue(at: cycle, in: registerValues) * cycle
        }.reduce(0, +)
    }

    private static func findRegisterValue(at desiredCycle: Int, in values: [(Int, Int)]) -> Int {

        let nextIndex = values.firstIndex { (cycle, _) in
            desiredCycle < cycle
        }

        // might have run past end of program, use last value / default 1st value
        guard let nextIndex else { return values.last?.1 ?? 1 }
        // handle first index matching, or empty collection
        guard nextIndex > values.startIndex else {
            return values.first?.1 ?? 1
        }
        
        let targetIndex = values.index(before: nextIndex)
        return values[targetIndex].1
    }
}
