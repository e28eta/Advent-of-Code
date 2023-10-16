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

public enum Pixel: CustomStringConvertible {
    case dark, lit

    public var description: String {
        switch self {
        case .dark:
            return "."
        case .lit:
            return "#"
        }
    }
}

public struct CPU {
    public private(set) var register: Int = 1
    public private(set) var cycle: Int = 1

    private var scheduledAddition: (cycle: Int, value: Int)?

    private var instructions: any IteratorProtocol<Instruction>

    public init(instructions: some IteratorProtocol<Instruction>) {
        self.instructions = instructions
    }

    public mutating func apply(instruction: Instruction) {
        switch instruction {
        case .noop:
            cycle += 1
        case .addx(let value):
            cycle += 2
            register += value
        }
    }

    public mutating func tick() -> Pixel {
        // begin
        // check to see if we need a new instruction
        if scheduledAddition == nil,
           // read next instruction
           let nextInstruction = instructions.next(),
           // handle addx
           case .addx(let value) = nextInstruction {
            scheduledAddition = (cycle: cycle + 1, value: value)
        } // else continue previous addx, or noop

        // draw
        let currentPixelIndex = ((cycle - 1) % CRT.columnCount)
        let spriteLocation = (register-1)...(register+1)
        
        let pixel: Pixel = (spriteLocation.contains(currentPixelIndex)
                            ? .lit
                            : .dark)


        // end
        if scheduledAddition?.cycle == cycle {
            register += scheduledAddition!.value
            scheduledAddition = nil
        }
        cycle += 1

        return pixel
    }
}

public struct Program {
    public let instructions: [Instruction]

    public init(code: String) {
        instructions = code.lines().compactMap(Instruction.init)
    }
}

public struct CRT: CustomStringConvertible {
    static let columnCount = 40
    public let pixels: [ArraySlice<Pixel>]

    public init?(pixels: [Pixel]) {
        guard pixels.count == 240 else { return nil }

        self.pixels = pixels.sliced(into: CRT.columnCount)
    }

    public var description: String {
        return pixels.map { row in
            row.map(\.description).joined(separator: "")
        }.joined(separator: "\n")
    }
}

public class HandheldDevice {
    let program: Program

    public init(code: String) {
        program = Program(code: code)
    }

    public func part1() -> Int {
        var cpu = CPU(instructions: program.instructions.makeIterator())

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

    public func part2() -> CRT? {
        var cpu = CPU(instructions: program.instructions.makeIterator())

        let pixels = (0..<240).map { _ in
            cpu.tick()
        }

        return CRT(pixels: pixels)
    }
}
