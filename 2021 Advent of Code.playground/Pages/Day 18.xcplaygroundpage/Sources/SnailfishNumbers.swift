import Foundation

public enum SnailfishNumber {
    indirect case pair(left: SnailfishNumber, right: SnailfishNumber)
    case regular(Int)
}

public extension SnailfishNumber {
    var magnitude: Int {
        switch self {
        case .pair(let left, let right):
            return left.magnitude * 3 + right.magnitude * 2
        case .regular(let int):
            return int
        }
    }
}

//MARK: Adding

public extension SnailfishNumber {
    static func +(_ left: SnailfishNumber, _ right: SnailfishNumber) -> SnailfishNumber {
        return .pair(left: left, right: right)
    }
}

//MARK: Reducing

public extension SnailfishNumber {
    mutating func reduce() {
        while self.reduceOnce() {
            continue
        }
    }

    mutating func reduceOnce() -> Bool {
        if self.canExplode(depth: 1) {
            _ = self.explode(depth: 1)
            return true
        } else if self.canSplit() {
            self.split()
            return true
        } else {
            return false
        }
    }
}

//MARK: Explosion-related modifications

public extension SnailfishNumber {
    func canExplode(depth: Int) -> Bool {
        guard case let .pair(left, right) = self else {
            return false
        }

        return (depth > 4
                || left.canExplode(depth: depth + 1)
                || right.canExplode(depth: depth + 1))
    }

    mutating func explode(depth: Int) -> (Int?, Int?) {
        if case let .pair(.regular(left),
                          .regular(right)) = self,
           depth > 4 {
            // found the pair of regular numbers
            self = .regular(0)
            return (left, right)
        }

        guard case .pair(var left, var right) = self else {
            preconditionFailure("wrong branch exploded?")
        }

        if left.canExplode(depth: depth + 1) {
            var (addToPrevious, addToSuccessor) = left.explode(depth: depth + 1)

            if addToSuccessor != nil {
                right.add(addToSuccessor!, location: .first)
                addToSuccessor = nil
            }

            self = .pair(left: left,
                         right: right)

            return (addToPrevious, addToSuccessor)
        } else {
            precondition(right.canExplode(depth: depth + 1), "neither child could explode!")

            var (addToPrevious, addToSuccessor) = right.explode(depth: depth + 1)

            if addToPrevious != nil {
                left.add(addToPrevious!, location: .last)
                addToPrevious = nil
            }

            self = .pair(left: left,
                         right: right)

            return (addToPrevious, addToSuccessor)
        }
    }

    enum Location {
        case first, last
    }

    mutating func add(_ amount: Int, location: Location) {

        switch self {
        case .regular(let int):
            self = .regular(int + amount)

        case var .pair(left, right):
            switch location {
            case .first:
                left.add(amount, location: location)
            case .last:
                right.add(amount, location: location)
            }

            self = .pair(left: left,
                         right: right)
        }
    }
}

//MARK: Splitting numbers

public extension SnailfishNumber {
    func canSplit() -> Bool {
        switch self {
        case .pair(let left, let right):
            return left.canSplit() || right.canSplit()
        case .regular(let int):
            return int >= 10
        }
    }

    mutating func split() {
        switch self {
        case var .pair(left, right):
            if left.canSplit() {
                left.split()
            } else if right.canSplit() {
                right.split()
            } else {
                preconditionFailure("tried to split un-splittable number")
            }
            self = .pair(left: left,
                         right: right)
        case .regular(let int):
            precondition(int >= 10, "value too low to split: \(int)")
            let left = int / 2
            let right = int - left

            self = .pair(left: .regular(left),
                         right: .regular(right))
        }
    }
}


//MARK: Parsing from string

public extension SnailfishNumber {
    init(_ string: String) {
        guard let num = SnailfishNumber(Scanner(string: string)) else {
            preconditionFailure("invalid string")
        }
        self = num
    }

    init?(_ scanner: Scanner, depth: Int = 1) {
        if scanner.scanString("[") != nil {
            let left = SnailfishNumber(scanner, depth: depth + 1)
            assert(left != nil, "expected left number at \(scanner.currentIndex)")

            assert(scanner.scanString(",") != nil, "expected comma at \(scanner.currentIndex)")

            let right = SnailfishNumber(scanner, depth: depth + 1)
            assert(right != nil, "expected right number at \(scanner.currentIndex)")

            assert(scanner.scanString("]") != nil, "expected ]  at \(scanner.currentIndex)")

            self = .pair(left: left!, right: right!)
        } else if let int = scanner.scanInt() {
            self = .regular(int)
        } else {
            preconditionFailure("next character didn't match opening brace or an integer at \(scanner.currentIndex): \(String(describing: scanner.scanCharacter())) ")
        }
    }
}

extension SnailfishNumber: CustomStringConvertible {
    public var description: String {
        switch self {
        case .pair(let left, let right):
            return "[\(left.description),\(right.description)]"
        case .regular(let int):
            return String(describing: int)
        }
    }
}
