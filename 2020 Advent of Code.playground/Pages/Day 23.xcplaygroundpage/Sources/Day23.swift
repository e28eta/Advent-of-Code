import Foundation

struct RepeatingCollection<A: RandomAccessCollection>: RandomAccessCollection where A.Index == Int {
    typealias Element = A.Element
    typealias Index = A.Index
    typealias Indices = Range<A.Index>

    let wrapped: A
    let wrappedLength: Int

    let startIndex: Int = 0
    var endIndex: Int = Int.max

    init(_ wrapped: A) {
        self.wrapped = wrapped
        self.wrappedLength = wrapped.count
    }

    subscript(index: Int) -> A.Element {
        get {
            wrapped[wrapped.startIndex + index % wrappedLength]
        }
    }
}

public struct CrabCups {
    /// Array of cups, value is the "name" / number of the cup
    var cups: [Int]
    /// Total number of cups
    let cupCount: Int
    /// index of the current cup
    var currentCup: Int
    /// name/number of the largest cup
    let maxCup: Int
    /// name/number of the smallest cup
    let minCup: Int

    public init(_ string: String, additionalCupCount: Int = 0) {
        let labeledCups = string.compactMap({ Int(String($0)) })
        let unlabeledCupStart = 1 + (labeledCups.max() ?? 0)
        let additionalCups = unlabeledCupStart ..< unlabeledCupStart + additionalCupCount

        cups = labeledCups + additionalCups
        cupCount = cups.count
        currentCup = 0
        maxCup = cups.max()!
        minCup = cups.min()!
    }

    public mutating func move(times: UInt) {
        for _ in (0 ..< times) {
            move()
        }
    }

    public mutating func move() {
        /*
         TODO: what I actually need is a linked list structure.
         pointer to current cup, which is a class object
         take out next 3 cups, by updating current cup.next to be N+3
         `destinationValue()` works fine as-is, I think
         optionally maintain hash of cup name to cup node, otherwise linear search for the destination cup node
         insert removed cups by updating the dest.next and removed.last.next
         current = current.next
         */
        let currentCupValue = cups[currentCup]
        var removedCups: [Int] = []

        for _ in (0..<3) {
            if currentCup + 1 < cups.count {
                removedCups += [cups.remove(at: currentCup + 1)]
            } else {
                removedCups += [cups.remove(at: 0)]
            }
        }

        let destinationCupValue = destinationValue(for: currentCupValue, removedCups: removedCups)
        let destinationIndex = (cups.firstIndex(of: destinationCupValue)! + 1) % cupCount
        cups.insert(contentsOf: removedCups, at: destinationIndex)

        currentCup = (cups.firstIndex(of: currentCupValue)! + 1) % cupCount
    }

    func destinationValue<C: Collection>(for current: Int, removedCups: C) -> Int where C.Element == Int {
        var candidate = current - 1

        while true {
            if removedCups.contains(candidate) {
                candidate -= 1
            } else if candidate < minCup {
                candidate = maxCup
            } else /* minCup <= candidate <= maxCup && !contains */ {
                return candidate
            }
        }
    }

    public var cupString: String {
        let idx = cups.firstIndex(of: 1)!
        return RepeatingCollection(cups).lazy.dropFirst(idx + 1).prefix(cupCount - 1).map(\.description).joined()
    }

    public var partTwoValue: Int {
        let idx = cups.firstIndex(of: 1)!
        return RepeatingCollection(cups).lazy.dropFirst(idx + 1).prefix(2).reduce(1, *)
    }
}


public struct LinkedCrabCups {
    /// LinkedList of cups, where value is the name / number of the cup
    var cupList: LinkedList<Int>
    /// name/number of the largest cup
    let maxCup: Int
    /// name/number of the smallest cup
    let minCup: Int

    public init(_ string: String, additionalCupCount: Int = 0) {
        let labeledCups = string.compactMap({ Int(String($0)) })
        let unlabeledCupStart = 1 + (labeledCups.max() ?? 0)
        let additionalCups = unlabeledCupStart ..< unlabeledCupStart + additionalCupCount

        cupList = LinkedList(labeledCups + additionalCups)

        minCup = labeledCups.min() ?? 1
        maxCup = additionalCups.endIndex - 1
    }

    public mutating func move(times: UInt) {
        for _ in (0 ..< times) {
            move()
        }
    }

    public mutating func move() {
        // go ahead and remove current cup from the list, won't be used until added to the end
        let currentCupValue = cupList.removeFirst()

        // take out next three cups, and remember which ones they are
        let removedCups = (0..<3).map { _ in cupList.removeFirst() }

        // find label of destination, given current value, the removed cups, and our min / max values
        let destinationCupValue = destinationValue(for: currentCupValue, removedCups: removedCups)

        // find index where destination occurs, guaranteed to exist based on problem statement, and insert after it
        let destinationIndex = cupList.firstIndex(of: destinationCupValue)!.advanced(by: 1)
        cupList.insert(contentsOf: removedCups, at: destinationIndex)

        // move clockwise one step, by moving head of list to the tail
        cupList.append(currentCupValue)
    }

    func destinationValue<C: Collection>(for current: Int, removedCups: C) -> Int where C.Element == Int {
        var candidate = current - 1

        while true {
            if removedCups.contains(candidate) {
                candidate -= 1
            } else if candidate < minCup {
                candidate = maxCup
            } else /* minCup <= candidate <= maxCup && !contains */ {
                return candidate
            }
        }
    }

    public var partTwoValue: Int {
        // worst case cup #1 is at the end, just append first two numbers to the end of cupList and go
        var extendedCupList = LinkedList(cupList)
        extendedCupList.append(contentsOf: cupList.prefix(2))

        return extendedCupList
            .drop { $0 != 1 } // find cup with value == 1
            .dropFirst() // ignore that one
            .prefix(2) // take next two
            .reduce(1, *) // multiply together
    }
}
