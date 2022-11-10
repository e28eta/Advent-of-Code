import Foundation

public typealias MemoryAddress = Int
public typealias Value = Int

public struct IntcodeComputer {
    public private(set) var running: Bool
    public private(set) var instructionPointer: MemoryAddress

    public private(set) var memory: [Value]

    public var input: IndexingIterator<Array<Value>>?
    public private(set) var output: [Value] = []

    public init(_ inputString: String) {
        self.init(inputString.split(separator: ",").compactMap(Int.init))
    }

    public init<S: Sequence<Value>>(_ initial: S) {
        self.running = true
        self.instructionPointer = 0
        self.memory = Array(initial)
    }

    public mutating func run() throws {
        while running {
            try step()
        }
    }

    public mutating func step() throws {
        let op = try IntcodeOperator(memory[instructionPointer...])
        var didJump = false

        switch op {
        case let .add(left: left, right: right, destination: destination):
            memory[destination] = value(for: left) + value(for: right)
        case let .multiply(left: left, right: right, destination: destination):
            memory[destination] = value(for: left) * value(for: right)
        case let .input(destination):
            guard let val = input?.next() else { fatalError("not enough input") }
            memory[destination] = val
        case let .output(source):
            output.append(value(for: source))
        case .halt:
            running = false
        case let .jumpIfTrue(compare: compare, newInstructionPointer: newInstructionPointer):
            if value(for: compare) != 0 {
                instructionPointer = value(for: newInstructionPointer)
                didJump = true
            }
        case let .jumpIfFalse(compare: compare, newInstructionPointer: newInstructionPointer):
            if value(for: compare) == 0 {
                instructionPointer = value(for: newInstructionPointer)
                didJump = true
            }
        case let .lessThan(left: left, right: right, destination: destination):
            memory[destination] = value(for: left) < value(for: right) ? 1 : 0
        case let .equals(left: left, right: right, destination: destination):
            memory[destination] = value(for: left) == value(for: right) ? 1 : 0
        }

        if running && !didJump {
            instructionPointer += op.numberOfValues
        }
    }

    public mutating func set(noun: Value, verb: Value) {
        precondition((0...99).contains(noun))
        precondition((0...99).contains(verb))

        memory[1] = noun
        memory[2] = verb
    }

    public func read(_ address: MemoryAddress) -> Value {
        return memory[address]
    }

    private func value(for parameter: IntcodeOperator.Parameter) -> Value {
        switch parameter {
        case .position(let int):
            return memory[int]
        case .immediate(let int):
            return int
        }
    }
}

enum IntcodeOperator {
    enum Parameter {
        /// the value stored in memory at the Int
        case position(MemoryAddress)
        /// the value of the Int
        case immediate(Value)
    }

    /// add left and right, store into destination
    case add(left: Parameter, right: Parameter, destination: MemoryAddress)
    /// multiply left and right, store into destination
    case multiply(left: Parameter, right: Parameter, destination: MemoryAddress)
    /// read one input value, store into destination
    case input(destination: MemoryAddress)
    /// write value from source to the output
    case output(source: Parameter)
    /// jump to newInstructionPointer if compare is non-zero
    case jumpIfTrue(compare: Parameter, newInstructionPointer: Parameter)
    /// jump to newInstructionPointer if compare is zero
    case jumpIfFalse(compare: Parameter, newInstructionPointer: Parameter)
    /// if left < right, write 1 to destination, else write 0
    case lessThan(left: Parameter, right: Parameter, destination: MemoryAddress)
    /// if left == right, write 1 to destination, else write 0
    case equals(left: Parameter, right: Parameter, destination: MemoryAddress)
    /// Stop running
    case halt

    init<S: Sequence<Int>>(_ memory: S) throws {
        var memoryIterator = memory.makeIterator()

        var opCode = memoryIterator.next()!

        // figure out modes, greedily
        let p1Mode, p2Mode: Int
//        (p3Mode, opCode) = opCode.quotientAndRemainder(dividingBy: 10_000)
        (p2Mode, opCode) = opCode.quotientAndRemainder(dividingBy: 1_000)
        (p1Mode, opCode) = opCode.quotientAndRemainder(dividingBy: 100)

        switch (opCode) {
        case 1:
            self = .add(left: Parameter(memoryIterator.next()!, mode: p1Mode),
                        right: Parameter(memoryIterator.next()!, mode: p2Mode),
                        destination: memoryIterator.next()!)
        case 2:
            self = .multiply(left: Parameter(memoryIterator.next()!, mode: p1Mode),
                             right: Parameter(memoryIterator.next()!, mode: p2Mode),
                             destination: memoryIterator.next()!)
        case 3:
            self = .input(destination: memoryIterator.next()!)
        case 4:
            self = .output(source: Parameter(memoryIterator.next()!, mode: p1Mode))
        case 5:
            self = .jumpIfTrue(compare: Parameter(memoryIterator.next()!, mode: p1Mode),
                               newInstructionPointer: Parameter(memoryIterator.next()!, mode: p2Mode))
        case 6:
            self = .jumpIfFalse(compare: Parameter(memoryIterator.next()!, mode: p1Mode),
                                newInstructionPointer: Parameter(memoryIterator.next()!, mode: p2Mode))
        case 7:
            self = .lessThan(left: Parameter(memoryIterator.next()!, mode: p1Mode),
                             right: Parameter(memoryIterator.next()!, mode: p2Mode),
                             destination: memoryIterator.next()!)
        case 8:
            self = .equals(left: Parameter(memoryIterator.next()!, mode: p1Mode),
                           right: Parameter(memoryIterator.next()!, mode: p2Mode),
                           destination: memoryIterator.next()!)
        case 99:
            self = .halt
        default:
            fatalError("invalid opCode \(String(describing: opCode))")
        }
    }

    var numberOfValues: Int {
        switch self {
        case .add, .multiply: return 4
        case .input, .output: return 2
        case .jumpIfTrue, .jumpIfFalse: return 3
        case .lessThan, .equals: return 4
        case .halt: return 1
        }
    }
}

extension IntcodeOperator.Parameter {
    init(_ value: Int, mode: Int = 0) {
        switch mode {
        case 0:
            self = .position(value)
        case 1:
            self = .immediate(value)
        default:
            fatalError("invalid mode \(mode)")
        }
    }
}
