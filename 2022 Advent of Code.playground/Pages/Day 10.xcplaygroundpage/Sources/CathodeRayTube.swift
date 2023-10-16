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
    /// current register value
    public private(set) var register: Int = 1
    /// current cycle count
    public private(set) var cycle: Int = 1
    /// pixel that will be drawn during the current cycle, based on current register value
    var pixel: Pixel {
        let currentPixelIndex = ((cycle - 1) % CRT.columnCount)
        let spriteLocation = (register-1)...(register+1)

        return (spriteLocation.contains(currentPixelIndex)
                ? .lit
                : .dark)

    }

    private var instructions: any IteratorProtocol<Instruction>
    private var scheduledAddition: (cycle: Int, value: Int)?

    public init(instructions: some IteratorProtocol<Instruction>) {
        self.instructions = instructions
    }

    public mutating func tick() {
        // check to see if we need a new instruction
        if scheduledAddition == nil,
           // read next instruction
           let nextInstruction = instructions.next(),
           // handle addx
           case .addx(let value) = nextInstruction {
            scheduledAddition = (cycle: cycle + 1, value: value)
        } // else continue previous addx, or noop

        // "during cycle" steps should happen prior to call to `tick()`
        // whether reading the register or figuring out pixel value

        // end of cycle updates
        if scheduledAddition?.cycle == cycle {
            register += scheduledAddition!.value
            scheduledAddition = nil
        }
        cycle += 1
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

        let targetCycles = [20, 60, 100, 140, 180, 220]
        var signalStrengthSum = 0

        while cpu.cycle <= targetCycles.last! {
            if targetCycles.contains(cpu.cycle) {
                signalStrengthSum += (cpu.cycle * cpu.register)
            }
            cpu.tick()
        }

        return signalStrengthSum
    }

    public func part2() -> CRT? {
        var cpu = CPU(instructions: program.instructions.makeIterator())

        let pixels = (0..<240).map { _ in
            defer { cpu.tick() }
            return cpu.pixel
        }

        return CRT(pixels: pixels)
    }
}
