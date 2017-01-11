import Foundation

public enum Register {
    case a, b, c, d

    init(_ string: String) {
        switch string {
        case "a": self = .a
        case "b": self = .b
        case "c": self = .c
        case "d": self = .d
        default: fatalError("unrecognized Register: \(string)")
        }
    }
}

public enum Value {
    case int(Int)
    case register(Register)

    init(_ string: String) {
        if let intValue = Int(string, radix: 10) {
            self = .int(intValue)
        } else {
            self = .register(Register(string))
        }
    }
}

public enum Instruction: CustomStringConvertible {
    case Copy(Value, Register)
    case Increment(Register)
    case Decrement(Register)
    case JumpNotZero(Value, delta: Int, lineNumber: Int)
    // Meta-instructions added by the optimizer
    case Add(destination: Register, source: Register)
    case Subtract(destination: Register, source: Register)
    case SetToZero(Register)

    public init(lineNumber: Int, instruction string: String) {
        let components = string.components(separatedBy: " ")

        switch components[0] {
        case "cpy":
            self = .Copy(Value(components[1]), Register(components[2]))
        case "inc":
            self = .Increment(Register(components[1]))
        case "dec":
            self = .Decrement(Register(components[1]))
        case "jnz":
            guard let delta = Int(components[2], radix: 10) else { fatalError("unreadable delta") }
            self = .JumpNotZero(Value(components[1]), delta: delta, lineNumber: lineNumber)
        default:
            fatalError("unrecognized Instruction: \(string)")
        }
    }

    public var description: String {
        switch self {
        case .Copy(_, _): return "cpy"
        case .Increment(_): return "inc"
        case .Decrement(_): return "dec"
        case .JumpNotZero(_, let delta, let lineNumber): return "jnz \(delta + lineNumber)"
        case .Add(let dest, let source): return "\(dest) += \(source)"
        case .Subtract(let dest, let source): return "\(dest) -= \(source)"
        case .SetToZero(let reg): return "\(reg) = 0"
        }
    }

    var registerModified: Register? {
        switch self {
        case .Copy(_, let r),
             .Increment(let r),
             .Decrement(let r),
             .Add(let r, _),
             .Subtract(let r, _),
             .SetToZero(let r):
            return r
        case .JumpNotZero(_, _, _):
            return nil
        }
    }
}

public struct RegisterFile {
    var a: Int = 0
    var b: Int = 0
    var c: Int = 0
    var d: Int = 0

    public subscript(register: Register) -> Int {
        get {
            switch register {
            case .a: return a
            case .b: return b
            case .c: return c
            case .d: return d
            }

        }
        set(newValue) {
            switch register {
            case .a: a = newValue
            case .b: b = newValue
            case .c: c = newValue
            case .d: d = newValue
            }
        }
    }

    subscript(value: Value) -> Int {
        switch value {
        case .int(let intValue):
            return intValue
        case .register(let register):
            return self[register]
        }
    }
}

public struct BasicBlock: CustomStringConvertible {
    let lineNumber: Int
    private let nextBlock: Int
    private let instructions: [Instruction]

    init(lineNumber: Int, nextBlock: Int, instructions: AnySequence<Instruction>) {
        self.lineNumber = lineNumber
        self.nextBlock = nextBlock

        var optimizedInstructions = Array(instructions)

        // special-case for construct that appears several times:
        if let lastInstruction = optimizedInstructions.last,
            case let .JumpNotZero(.register(comparisonRegister), delta, lineNumber) = lastInstruction,
            (lineNumber + delta) == self.lineNumber {
            // The last instruction of this block is JNZ back to the beginning of the block

            let decrementComparison = { (instruction: Instruction) -> Bool in
                if case let .Decrement(reg) = instruction, comparisonRegister == reg {
                    return true
                } else {
                    return false
                }
            }

            if optimizedInstructions.filter({ $0.registerModified == comparisonRegister }).count == 1,
                let indexOfDecrement = optimizedInstructions.index(where: decrementComparison),
                optimizedInstructions.filter({ if case let .Copy(.register(reg), _) = $0, reg == comparisonRegister { return true } else { return false } }).count == 0 {
                // There is a single instruction that modifies the Register that's used in the JNZ, and it's
                // a Decrement instruction, and that register is never used as the source of a Copy

                // Convert this block to *not* loop
                // decrementing $comparisonRegister times is just set to zero)
                optimizedInstructions[indexOfDecrement] = .SetToZero(comparisonRegister)
                optimizedInstructions.removeLast() // Remove JNZ block

                optimizedInstructions = optimizedInstructions.enumerated().flatMap { (index, instruction) -> [Instruction] in
                    switch instruction {
                    case let .Increment(register):
                        // Instead of incrementing N times, just add
                        let add = Instruction.Add(destination: register, source: comparisonRegister)

                        if index >= indexOfDecrement {
                            // If this add happened *after* the decrement of comparisonRegister, it should be += (n-1)
                            return [add, .Decrement(register)]
                        } else {
                            return [add]
                        }
                    case let .Decrement(register):
                        let sub = Instruction.Subtract(destination: register, source: comparisonRegister)
                        if index >= indexOfDecrement {
                            return [sub, .Increment(register)]
                        } else {
                            return [sub]
                        }
                    default:
                        // The only other (non-optimized) instruction possible is copy, which should be fine un-modified
                        return [instruction]
                    }
                }



            }

        }

        self.instructions = optimizedInstructions
    }

    public var description: String {
        return "\(lineNumber): " + instructions.enumerated().map { $1.description }.joined(separator: ",  ")
    }

    func execute(state: RegisterFile) -> (RegisterFile, Int) {
        var registers = state
        var nextBlock = self.nextBlock

        for instruction in instructions {
            switch instruction {
            case let .Copy(val, reg):
                registers[reg] = registers[val]
            case let .Increment(reg):
                registers[reg] += 1
            case let .Decrement(reg):
                registers[reg] -= 1
            case let .JumpNotZero(val, delta, lineNumber):
                if registers[val] != 0 {
                    nextBlock = delta + lineNumber
                    break // skip PC increment
                }

            // Optimized instructions
            case let .Add(dest, source):
                registers[dest] += registers[source]
            case let .Subtract(dest, source):
                registers[dest] -= registers[source]
            case let .SetToZero(reg):
                registers[reg] = 0
            }
        }

        return (registers, nextBlock)
    }
}

public func controlFlowGraph(_ instructions: [Instruction]) -> [BasicBlock] {
    var leaders = Set<Int>()
    leaders.insert(instructions.startIndex)
    leaders.insert(instructions.endIndex) // not technically a leader, but makes iterating through pairs easier

    for case let .JumpNotZero(_, delta, lineNumber) in instructions {
        leaders.insert(lineNumber + 1)
        leaders.insert(lineNumber + delta)
    }

    let indices = leaders.sorted()

    return zip(indices, indices.dropFirst()).map { (begin: Int, end: Int) -> BasicBlock in
        BasicBlock(lineNumber: begin, nextBlock: end, instructions: AnySequence(instructions[(begin..<end)]))
    }
}

struct Program {
    var firstBlock: BasicBlock? { return blocks[0] }
    var blocks: [Int: BasicBlock]

    init(instructions: [Instruction]) {
        blocks = [:]

        for block in controlFlowGraph(instructions) {
            blocks[block.lineNumber] = block
        }
    }
}


public struct Machine {
    public var registers = RegisterFile()
    var program: Program

    public init(_ instructions: [Instruction]) {
        self.program = Program(instructions: instructions)
    }

    public mutating func execute() {
        var nextBlock = program.firstBlock

        while let block = nextBlock {
            let (newState, nextBlockIndex) = block.execute(state: registers)
            registers = newState
            nextBlock = program.blocks[nextBlockIndex]
        }
    }
    
    public mutating func reset() {
        self.registers = RegisterFile()
    }
}
