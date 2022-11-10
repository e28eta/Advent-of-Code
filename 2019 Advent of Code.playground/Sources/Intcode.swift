import Foundation

public struct IntcodeComputer {
    public private(set) var running: Bool
    public private(set) var programCounter: Int

    public private(set) var memory: [Int]

    public init(_ inputString: String) {
        self.init(inputString.split(separator: ",").compactMap(Int.init))
    }

    public init<S: Sequence<Int>>(_ initial: S) {
        self.running = true
        self.programCounter = 0
        self.memory = Array(initial)
    }

    public mutating func run() throws {
        while running {
            try step()
        }
    }

    public mutating func step() throws {
        let op = try IntcodeOperator(memory[programCounter...])

        switch op {
        case let .add(left: left, right: right, destination: destination):
            memory[destination] = memory[left] + memory[right]
        case let .multiply(left: left, right: right, destination: destination):
            memory[destination] = memory[left] * memory[right]
        case .halt:
            running = false
        }

        if running {
            incrementProgramCounter()
        }
    }

    public mutating func fix(_ modifications: (inout [Int]) -> ()) {
        modifications(&self.memory)
    }

    private mutating func incrementProgramCounter() {
        programCounter += 4
    }
}

enum IntcodeOperator {
    case add(left: Int, right: Int, destination: Int)
    case multiply(left: Int, right: Int, destination: Int)
    case halt

    init<S: Sequence<Int>>(_ memory: S) throws {
        var memoryIterator = memory.makeIterator()

        let opCode = memoryIterator.next()
        switch opCode {
        case 1:
            self = .add(left: memoryIterator.next()!, right: memoryIterator.next()!, destination: memoryIterator.next()!)
        case 2:
            self = .multiply(left: memoryIterator.next()!, right: memoryIterator.next()!, destination: memoryIterator.next()!)
        case 99:
            self = .halt
        default:
            fatalError("invalid opCode \(String(describing: opCode))")
        }
    }
}
