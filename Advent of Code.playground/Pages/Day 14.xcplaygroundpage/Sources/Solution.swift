import Foundation

extension String {
    public func repeatedChars() -> (Character, Set<Character>)? {
        var tripletCharacter: Character? = nil
        var quintChars: Set<Character> = []

        var currentChar = self.characters.first!
        var count = 0

        for char in self.characters {
            if char == currentChar {
                count += 1

                if count == 3 && tripletCharacter == nil {
                    tripletCharacter = char
                } else if count == 5 {
                    quintChars.insert(char)
                }
            } else {
                currentChar = char
                count = 1
            }
        }

        if let tripletCharacter = tripletCharacter {
            return (tripletCharacter, quintChars)
        } else {
            return nil
        }
    }

    public func randomDataStream() -> AnySequence<(Int, String)> {
        return AnySequence<(Int, String)> { () -> AnyIterator<(Int, String)> in
            var index = -1

            return AnyIterator<(Int, String)> {
                index += 1
                let candidate = (self + String(index, radix: 10)).md5()

                return (index, candidate)
            }
        }
    }
}

extension Array where Element: Comparable {

    public func findInsertionIndex(_ element: Element, in subrange: Range<Int>? = nil) -> Int {
        let rangeToSearch = NSRange(subrange ?? (0..<endIndex))

        let ascending = { (lhs: Any, rhs: Any) -> ComparisonResult in
            guard let lhs = lhs as? Element, let rhs = rhs as? Element else {
                return .orderedSame // How'd we break type safety?
            }

            if lhs < rhs {
                return .orderedAscending
            } else if lhs == rhs {
                return .orderedSame
            } else {
                return .orderedDescending
            }
        }

        return (self as NSArray).index(of: element, inSortedRange: rangeToSearch, options: .insertionIndex, usingComparator: ascending)
    }
}

public class CandidateKeys {
    var triples: [(Int, Character)] = []
    var quintuples: [Character: [Int]] = [:]

    var lastHashIndex: Int = -1
    private var hashStream: AnyIterator<(Int, Character, Set<Character>)>
    private lazy var tripleStream: AnyIterator<(Int, Character)> = {
        var index = 0

        return AnyIterator {
            if index == self.triples.endIndex {
                self.consume()
            }

            defer { index += 1 }
            return self.triples[index]
        }
    }()
    public lazy var keyStream: AnyIterator<Int> = {
        return AnyIterator {
            repeat {
                guard let (index, triple) = self.tripleStream.next() else { fatalError("ran out of triples?") }
                if self.isKey(index, triple: triple) {
                    return index
                }
            } while true
        }
    }()

    public init(dataStream: AnySequence<(Int, String)>) {
        let dataIterator = dataStream.makeIterator()

        hashStream = AnyIterator { () -> (Int, Character, Set<Character>)? in
            repeat {
                guard let (index, string) = dataIterator.next() else { return nil }
                guard let (triple, quints) = string.repeatedChars() else { continue }

                return (index, triple, quints)
            } while true
        }
    }

    func consume(upThrough upperBound: Int? = nil) {
        let upperBound = upperBound ?? (lastHashIndex + 1)

        while lastHashIndex < upperBound {
            guard let (index, triple, quints) = hashStream.next() else {
                fatalError("Ran out of hashes?")
            }

            self.add(index, triple: triple, quintuples: quints)
        }
    }


    func add(_ index: Int, triple: Character, quintuples: Set<Character>) {
        lastHashIndex = index
        triples.append((index, triple))

        for char in quintuples {
            if self.quintuples[char] == nil {
                self.quintuples[char] = [index]
            } else {
                self.quintuples[char]?.append(index)
            }
        }
    }

    func isKey(_ index: Int, triple: Character) -> Bool {
        self.consume(upThrough: index + 1000)

        guard let quints = self.quintuples[triple] else {
            // Never seen a quintuple of this character
            return false
        }

        let bounds = (index + 1)..<(index + 1000)

        // Where in the quints array would the result for lowerBound be?
        let expectedIndex = quints.findInsertionIndex(bounds.lowerBound)
        guard expectedIndex < quints.endIndex else {
            return false
        }

        // See if the result @ expectedIndex is within the bounds
        return bounds.contains(quints[expectedIndex])
    }
}
