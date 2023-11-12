import Foundation

public struct BingoBoard {
    /// where was this number on the board
    var numberToLocation: [Int: (r: Int, c: Int)]
    /// have we seen the number at this location yet
    var locations: [[Bool]]

    public init?(_ lines: any Collection<String>) {
        guard lines.count == 5 else { return nil }

        let locations = lines.map { line in
            line.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .compactMap(Int.init)
        }

        guard locations.allSatisfy({ $0.count == 5 }) else {
            return nil
        }

        self.locations = Array(repeating: Array(repeating: false, count: 5), count: 5)
        self.numberToLocation = locations
            .enumerated()
            .reduce([:]) { d, arg1 in
                let (rowNum, row) = arg1

                return row.enumerated()
                    .reduce(into: d) { d, arg2 in
                        let (colNum, number) = arg2
                        d[number] = (r: rowNum, c: colNum)
                    }
            }
    }

    /// mark the provided number, and check for BINGO
    public mutating func mark(_ number: Int) -> Bool {
        guard let (r, c) = numberToLocation[number] else {
            return false
        }

        locations[r][c] = true

        // check every entry in this row, and every row's entry for this column
        return (locations[r].allSatisfy({$0})
                || locations.allSatisfy({ $0[c] }))
    }

    public func score() -> Int {
        return numberToLocation
            .lazy
            .filter { _, loc in
                locations[loc.r][loc.c] == false
            }
            .map(\.key)
            .reduce(0, +)
    }
}

public struct BingoGame {
    var pickedNumbers: [Int]
    var boards: [BingoBoard]

    public init?(_ string: String) {
        var lines = string.lines()

        pickedNumbers = lines.removeFirst()
            .components(separatedBy: ",")
            .compactMap(Int.init)

        // make sure we read some numbers, 5 is arbitrary (and min needed for a game)
        guard pickedNumbers.count > 5 else { return nil }
        lines.removeFirst()

        boards = stride(from: lines.startIndex,
                        to: lines.endIndex,
                        by: 6)
        .compactMap { startIdx -> BingoBoard? in
            guard startIdx + 5 <= lines.endIndex else { return nil }
            return BingoBoard(lines[startIdx ..< (startIdx + 5)])
        }
    }

    public mutating func play() -> Int {
        for next in pickedNumbers {
            for boardIdx in boards.indices {
                if boards[boardIdx].mark(next) {
                    return next * boards[boardIdx].score()
                }
            }
        }

        return -1
    }
}
