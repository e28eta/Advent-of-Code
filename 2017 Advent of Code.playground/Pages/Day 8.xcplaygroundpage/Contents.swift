//: [Previous](@previous)

/*:
 # Day 8: I Heard You Like Registers

 You receive a signal directly from the CPU. Because of your recent assistance with [jump instructions](http://adventofcode.com/2017/day/5), it would like you to compute the result of a series of unusual register instructions.

 Each instruction consists of several parts: the register to modify, whether to increase or decrease that register's value, the amount by which to increase or decrease it, and a condition. If the condition fails, skip the instruction without modifying the register. The registers all start at 0. The instructions look like this:

 ```
 b inc 5 if a > 1
 a inc 1 if b < 5
 c dec -10 if a >= 1
 c inc -20 if c == 10
 ```

 These instructions would be processed as follows:

 - Because `a` starts at `0`, it is not greater than `1`, and so `b` is not modified.
 - `a` is increased by `1` (to `1`) because `b` is less than `5` (it is `0`).
 - `c` is decreased by `-10` (to `10`) because `a` is now greater than or equal to `1` (it is `1`).
 - `c` is increased by `-20` (to `-10`) because `c` is equal to `10`.

 After this process, the largest value in any register is `1`.

 You might also encounter `<=` (less than or equal to) or `!=` (not equal to). However, the CPU doesn't have the bandwidth to tell you what all the registers are named, and leaves that to you to determine.

 **What is the largest value in any register** after completing the instructions in your puzzle input?
*/

import Foundation

let testData = [
    ("""
b inc 5 if a > 1
a inc 1 if b < 5
c dec -10 if a >= 1
c inc -20 if c == 10
""", 1)
]

enum Operator: String {
    case gt = ">", gte = ">=", lt = "<", lte = "<=", eq = "==", neq = "!="

    var test: ((Int, Int) -> Bool) {
        switch self {
        case .gt: return (>)
        case .gte: return (>=)
        case .lt: return (<)
        case .lte: return (<=)
        case .eq: return (==)
        case .neq: return (!=)
        }
    }
}

enum Operation: String {
    case inc, dec

    var execute: (inout Int, Int) -> Void {
        switch self {
        case .inc: return (+=)
        case .dec: return (-=)
        }
    }
}

struct Instruction {
    let opRegister: String
    let op: Operation
    let opAmount: Int
    let comparisonRegister: String
    let comparison: Operator
    let comparisonValue: Int

    init(_ string: String) {
        let parts = string.components(separatedBy: " ")

        guard parts.count == 7,
            let op = Operation(rawValue: parts[1]),
            let opAmount = Int(parts[2]),
            let comparison = Operator(rawValue: parts[5]),
            let comparisonValue = Int(parts[6]) else {
                print("Unparseable: \(string)", string.split(separator: " "))
                fatalError()
        }

        opRegister = parts[0]
        self.op = op
        self.opAmount = opAmount

        // ignore 'if'

        comparisonRegister = parts[4]
        self.comparison = comparison
        self.comparisonValue = comparisonValue
    }

    func execute(_ registers: inout [String: Int]) {
        if comparison.test(registers[comparisonRegister, default: 0], comparisonValue) {
            op.execute(&registers[opRegister, default: 0], opAmount)
        }
    }
}

func largestValue(_ input: String) -> Int {
    let program = input.lines().map { Instruction($0) }
    var registers = [String: Int]()

    for instruction in program {
        instruction.execute(&registers)
    }

    return registers.values.max() ?? 0
}

verify(testData, { largestValue($0) })

let input = try readResourceFile("input.txt")
assertEqual(largestValue(input), 4877)

//: [Next](@next)
