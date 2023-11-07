import Foundation

/// Entry in the "encrypted" file
public struct EncryptionNumber {
    /// original position of the number in the file, so I can find each number in order
    let originalPosition: Int
    /// value of the number
    let value: Int
}

public class DecryptedMixing {
    public var list: LinkedList<EncryptionNumber>

    public init(_ string: String) {
        let numbers = string.lines()
            .compactMap(Int.init)
            .enumerated()
            .map { (idx, num) in
                EncryptionNumber(originalPosition: idx, value: num)
            }

        list = LinkedList(numbers)
    }

    public func part1() -> Int {
        for original in (0 ..< list.count) {
            // this search could be faster if I start partway through
            let currentIndex = list.firstIndex { $0.originalPosition == original }!
            let delta = list[currentIndex].value

            let moved = list.remove(at: currentIndex)
            // currentIndex is "invalid" once remove() called, but
            // I think it works for this specific use
            let destination = indexFrom(start: currentIndex,
                                        delta: delta)
            list.insert(moved, at: destination)
        }

        let zeroIndex = list.firstIndex { $0.value == 0 }!

        return [1000, 2000, 3000].reduce(0) { (sum, delta) in
            let index = indexFrom(start: zeroIndex, delta: delta)
            let value = list[index].value

            return sum + value
        }
    }

    private func indexFrom(start index: LinkedList<EncryptionNumber>.Index, delta: Int) -> LinkedList<EncryptionNumber>.Index {
        let indexDistance = list.startIndex.distance(to: index)

        // *after* remove(at:) has been called, so (N-1)
        let destinationDistance = mod(indexDistance + delta, list.count)

        // since this is O(n), start from whichever end of the list is
        // closer
        if destinationDistance > list.count / 2 {
            let distanceFromEnd = list.count - destinationDistance
            return list.endIndex.advanced(by: -1 * distanceFromEnd)
        } else {
            return list.startIndex.advanced(by: destinationDistance)
        }

    }
}

/// https://stackoverflow.com/a/41180619
fileprivate func mod(_ a: Int, _ n: Int) -> Int {
    precondition(n > 0, "modulus must be positive")
    let r = a % n
    return r >= 0 ? r : r + n
}

extension EncryptionNumber: CustomStringConvertible {
    public var description: String {
        return value.description
    }
}
