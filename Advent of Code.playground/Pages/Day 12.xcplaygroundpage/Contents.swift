//: [Previous](@previous)

/*:
 # Day 12: Leonardo's Monorail

 You finally reach the top floor of this building: a garden with a slanted glass ceiling. Looks like there are no more stars to be had.

 While sitting on a nearby bench amidst some [tiger lilies](https://www.google.com/search?q=tiger+lilies&tbm=isch), you manage to decrypt some of the files you extracted from the servers downstairs.

 According to these documents, Easter Bunny HQ isn't just this building - it's a collection of buildings in the nearby area. They're all connected by a local monorail, and there's another building not far from here! Unfortunately, being night, the monorail is currently not operating.

 You remotely connect to the monorail control systems and discover that the boot sequence expects a password. The password-checking logic (your puzzle input) is easy to extract, but the code it uses is strange: it's assembunny code designed for the [new computer](http://adventofcode.com/2016/day/11) you just assembled. You'll have to execute the code and get the password.

 The assembunny code you've extracted operates on four [registers](https://en.wikipedia.org/wiki/Processor_register) (`a`, `b`, `c`, and `d`) that start at `0` and can hold any [integer](https://en.wikipedia.org/wiki/Integer). However, it seems to make use of only a few [instructions](https://en.wikipedia.org/wiki/Instruction_set):

 `cpy x y` **copies** `x` (either an integer or the **value** of a register) into register `y`.
 `inc x` **increases** the value of register `x` by one.
 `dec x` **decreases** the value of register `x` by one.
 `jnz x y` **jumps** to an instruction `y` away (positive means forward; negative means backward), but only if `x` is **not zero**.
 The `jnz` instruction moves relative to itself: an offset of `-1` would continue at the previous instruction, while an offset of `2` would **skip over** the next instruction.

 For example:
 ````
 cpy 41 a
 inc a
 inc a
 dec a
 jnz a 2
 dec a
 ````
 The above code would set register `a` to `41`, increase its value by `2`, decrease its value by `1`, and then skip the last `dec a` (because `a` is not zero, so the `jnz a 2` skips it), leaving register `a` at `42`. When you move past the last instruction, the program halts.

 After executing the assembunny code in your puzzle input, **what value is left in register `a`?**

 */

import Foundation

enum Register {
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

enum Value {
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

enum Instruction {
    case Copy(Value, Register)
    case Increment(Register)
    case Decrement(Register)
    case JumpNotZero(Value, delta: Int, lineNumber: Int)
    // Meta-instructions added by the optimizer
    case Add(destination: Register, source: Register)
    case Subtract(destination: Register, source: Register)
    case SetToZero(Register)

    init(lineNumber: Int, instruction string: String) {
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

    var description: String {
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

struct RegisterFile {
    var a: Int = 0
    var b: Int = 0
    var c: Int = 0
    var d: Int = 0

    subscript(register: Register) -> Int {
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

struct BasicBlock: CustomStringConvertible {
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

    var description: String {
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

func controlFlowGraph(_ instructions: [Instruction]) -> [BasicBlock] {
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


struct Machine {
    var registers = RegisterFile()
    var program: Program

    init(_ instructions: [Instruction]) {
        self.program = Program(instructions: instructions)
    }

    mutating func execute() {
        var nextBlock = program.firstBlock

        while let block = nextBlock {
            let (newState, nextBlockIndex) = block.execute(state: registers)
            registers = newState
            nextBlock = program.blocks[nextBlockIndex]
        }
    }

    mutating func reset() {
        self.registers = RegisterFile()
    }
}

let exampleInstructions = ["cpy 41 a", "inc a", "inc a", "dec a", "jnz a 2", "dec a"].enumerated().map { Instruction(lineNumber: $0, instruction: $1) }
var exampleMachine = Machine(exampleInstructions)
exampleMachine.execute()
assert(exampleMachine.registers[.a] == 42)

let instructions = try readResourceFile("input.txt").components(separatedBy: .newlines).enumerated().map { Instruction(lineNumber: $0, instruction: $1) }

var machine = Machine(instructions)
machine.execute()
let part1Answer = machine.registers[.a]
assert(part1Answer == 318020)

/*:
 Part Two ---

 As you head down the fire escape to the monorail, you notice it didn't start; register c needs to be initialized to the position of the ignition key.

 If you instead initialize register c to be 1, what value is now left in register a?
 */


print(controlFlowGraph(instructions).map { $0.description }.joined(separator: "\n"))

machine.reset()
machine.registers[.c] = 1
machine.execute()
let part2Answer = machine.registers[.a]
assert(part2Answer == 9227674)

//: [Next](@next)
