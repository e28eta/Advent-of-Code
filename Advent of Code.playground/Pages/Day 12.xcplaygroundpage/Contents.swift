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
    case JumpNotZero(Value, Int)

    init(_ string: String) {
        let components = string.components(separatedBy: " ")

        switch components[0] {
        case "cpy":
            self = .Copy(Value(components[1]), Register(components[2]))
        case "inc":
            self = .Increment(Register(components[1]))
        case "dec":
            self = .Decrement(Register(components[1]))
        case "jnz":
            self = .JumpNotZero(Value(components[1]), Int(components[2], radix: 10)!)
        default:
            fatalError("unrecognized Instruction: \(string)")
        }
    }
}

struct Machine {
    var registers: [Register: Int] = [.a: 0, .b: 0, .c: 0, .d: 0]
    var instructions: [Instruction]

    init(_ instructions: [Instruction]) {
        self.instructions = instructions
    }

    mutating func execute() {
        var programCounter = instructions.startIndex

        while instructions.startIndex <= programCounter && programCounter < instructions.endIndex {
            switch instructions[programCounter] {
            case let .Copy(val, reg):
                registers[reg] = evaluate(val)
            case let .Increment(reg):
                registers[reg] = 1 + (registers[reg] ?? 0)
            case let .Decrement(reg):
                registers[reg] = -1 + (registers[reg] ?? 0)
            case let .JumpNotZero(val, delta):
                if evaluate(val) != 0 {
                    programCounter += delta
                    continue // skip PC increment
                }
            }

            programCounter += 1
        }
    }

    func evaluate(_ v: Value) -> Int {
        switch v {
        case .int(let i): return i
        case .register(let r): return registers[r]!
        }
    }
}

let exampleInstructions = ["cpy 41 a", "inc a", "inc a", "dec a", "jnz a 2", "dec a"].map { Instruction($0) }
var exampleMachine = Machine(exampleInstructions)
exampleMachine.execute()
assert(exampleMachine.registers[.a] == 42)

let instructions = try readResourceFile("input.txt").components(separatedBy: .newlines).flatMap { Instruction($0) }

//var machine = Machine(instructions)
//machine.execute()
//let part1Answer = machine.registers[.a]!
//assert(part1Answer == 318020)

/*:
 Part Two ---

 As you head down the fire escape to the monorail, you notice it didn't start; register c needs to be initialized to the position of the ignition key.

 If you instead initialize register c to be 1, what value is now left in register a?
 */

var machine = Machine(instructions)
machine.registers[.c] = 1
machine.execute()
let part2Answer = machine.registers[.a]

//: [Next](@next)
