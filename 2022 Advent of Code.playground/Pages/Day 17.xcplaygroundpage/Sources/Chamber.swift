import Foundation

public enum WindDirection: Character {
    case left = "<"
    case right = ">"

    public static func windPattern(_ string: String) -> some Sequence<(Int, WindDirection)> {
        return string
            .compactMap({ WindDirection(rawValue: $0) })
            .enumerated()
            .map { $0 } // convert from sequence to collection for `cycled()` 🤦‍♂️
            .cycled()
    }
}

extension WindDirection: CustomStringConvertible {
    public var description: String { return String(rawValue) }
}

enum Shape {
    case hyphen, plus, ell, pipe, square

    static func sequence() -> some Sequence<(Int, Shape)> {
        return [Shape.hyphen, .plus, .ell, .pipe, .square]
            .enumerated()
            .map { $0 }
            .cycled()
    }

    func bitwise() -> [Chamber.Row] {
        // top bit unused for 7-unit wide chamber
        // left edge is two units away, so upper 3 bits all 0
        switch self {
        case .hyphen:
            return [
                0b000_11110
            ]
        case .plus:
            return [
                0b000_01000,
                0b000_11100,
                0b000_01000
            ]
        case .ell:
            // "flipped" so that first row is bottom of shape
            return [
                0b000_11100,
                0b000_00100,
                0b000_00100
            ]
        case .pipe:
            return [
                0b000_10000,
                0b000_10000,
                0b000_10000,
                0b000_10000
            ]
        case .square:
            return [
                0b000_11000,
                0b000_11000
            ]
        }
    }
}

public struct Chamber {
    typealias Row = UInt8
    typealias BitwiseShape = [Row]

    static let leftBoundary: UInt8 =  0b0_100_0000
    static let rightBoundary: UInt8 = 0b0_000_0001
    static let rockAppearanceDelta = 3

    var rows = ChamberRows()

    struct DropDetails: Hashable {
        let shapeIndex: Int
        let windIndex: Int
        let rowsDropped: Int
        let horizontalPosition: UInt8
    }

    public init() { }

    public mutating func drop(_ totalDropCount: Int, wind windSequence: some Sequence<(Int, WindDirection)>) -> Int {
        var droppedShapes: [DropDetails: (height: Int, dropIdx: Int)] = [:]
        var rockAppearanceRow = Chamber.rockAppearanceDelta
        var wind = windSequence.makeIterator()
        var shapes = Shape.sequence().makeIterator()
        var consecutiveIdenticalDrops = 0
        var previousConsecutiveDropIndex: Int? = nil
        var dropIdx = 0
        var numCyclesSkipped: Int? = nil
        var cycleHeight: Int?

        while dropIdx < totalDropCount {
            defer { dropIdx += 1 }
            let (shapeIdx, shapeEnum) = shapes.next()!
            var bottomOfShape = rockAppearanceRow + 1 // due to shape of repeat/while loop
            var shape = shapeEnum.bitwise()
            var firstWindIndex: Int?

            repeat {
                let (windIdx, windDirection) = wind.next()!
                if firstWindIndex == nil {
                    firstWindIndex = windIdx
                }

                bottomOfShape -= 1
                shape = shift(shape: shape, windDirection, on: bottomOfShape)
            } while canDrop(shape, to: bottomOfShape - 1)

            settle(rock: shape, at: bottomOfShape)

            let thisDrop = DropDetails(shapeIndex: shapeIdx,
                                       windIndex: firstWindIndex!,
                                       rowsDropped: rockAppearanceRow - bottomOfShape,
                                       horizontalPosition: shape[0])

            let topOfShape = bottomOfShape + shape.count
            rockAppearanceRow = max(rockAppearanceRow,
                                    topOfShape + Chamber.rockAppearanceDelta)

            guard numCyclesSkipped == nil && cycleHeight == nil else {
                // don't need to calculate cycle anymore, found it!
                continue
            }

            let dropValues = (height: rockAppearanceRow - Chamber.rockAppearanceDelta,
                              dropIdx: dropIdx)

            let previousDropValues = droppedShapes.updateValue(dropValues, forKey: thisDrop)

            guard let previousDropValues else {
                // First time we've seen this drop, go to next shape
                previousConsecutiveDropIndex = nil
                consecutiveIdenticalDrops = 0
                continue
            }

            guard previousConsecutiveDropIndex != nil,
                  previousConsecutiveDropIndex! + 1 == previousDropValues.dropIdx else {
                // first repeated drop, or it's a repeated drop
                // that didn't come directly after the previous
                previousConsecutiveDropIndex = previousDropValues.dropIdx
                consecutiveIdenticalDrops = 1
                continue
            }

            // drop is consecutive with previous
            consecutiveIdenticalDrops += 1
            previousConsecutiveDropIndex = previousDropValues.dropIdx

            if (consecutiveIdenticalDrops > 5) {
                // _pretty_ sure we're in a cycle after 5
                let cycleLength = dropValues.dropIdx - previousDropValues.dropIdx

                numCyclesSkipped = (totalDropCount - dropIdx) / cycleLength
                cycleHeight = dropValues.height - previousDropValues.height

                dropIdx += numCyclesSkipped! * cycleLength
            }
        }

        if let numCyclesSkipped, let cycleHeight {
            print("FYI, skipped \(numCyclesSkipped) cycles, which would add \(cycleHeight) each time")
            rockAppearanceRow += numCyclesSkipped * cycleHeight
        }

        return rockAppearanceRow - Chamber.rockAppearanceDelta
    }

    func shift(shape: BitwiseShape, _ direction: WindDirection, on bottomRowIdx: Int) -> BitwiseShape {
        let shiftedShape: BitwiseShape

        switch direction {
        case .left:
            guard shape.allSatisfy({ $0 & Chamber.leftBoundary == 0 }) else {
                // shape is at left boundary, no shifting
                return shape
            }

            shiftedShape = shape.map { $0 << 1 }
        case .right:
            guard shape.allSatisfy({ $0 & Chamber.rightBoundary == 0 }) else {
                // shape is at right boundary, no shifting
                return shape
            }
            shiftedShape = shape.map { $0 >> 1 }
        }

        for (shapeIdx, chamberIdx) in zip(shiftedShape.indices, bottomRowIdx...) {
            if shiftedShape[shapeIdx] & rows[chamberIdx] != 0 {
                // found collision in shifted shape, no shift allowed
                return shape
            }
        }

        // shift succeeded
        return shiftedShape
    }

    func canDrop(_ shape: BitwiseShape, to destinationRowIdx: Int) -> Bool {
        // cannot drop below zero
        guard destinationRowIdx >= 0 else { return false }

        for (shapeIdx, chamberIdx) in zip(shape.indices, destinationRowIdx...) {
            if shape[shapeIdx] & rows[chamberIdx] != 0 {
                return false
            }
        }

        return true
    }

    mutating func settle(rock shape: BitwiseShape, at bottomRowIdx: Int) {
        let indices = zip(shape.indices, bottomRowIdx...)

        guard indices.allSatisfy({ shape[$0.0] & rows[$0.1] == 0 }) else {
            fatalError("Found collision during settling:\n\(shape)")
        }

        for (shapeIdx, chamberIdx) in indices {
            rows[chamberIdx] |= shape[shapeIdx]
        }
    }
}

struct ChamberRows {
    typealias Row = UInt8
    static let FullRow: UInt8 = 0b0_111_1111

    var rows: Array<Row> = []
    var bottomRowDelta = 0

    init() {

    }

    subscript(index: Int) -> Row {
        get {
            let rowsIndex = index - bottomRowDelta

            guard rowsIndex >= rows.startIndex else {
                fatalError("tried to access a pruned row \(index) below the bottom of rows at \(bottomRowDelta)")
            }

            if rowsIndex >= rows.endIndex {
                return 0 // row hasn't been stored to yet, it is empty
            } else {
                return rows[rowsIndex]
            }
        }

        set(newValue) {
            let rowsIndex = index - bottomRowDelta

            guard rowsIndex >= rows.startIndex else {
                fatalError("tried to access a pruned row \(index) below the bottom of rows at \(bottomRowDelta)")
            }

            if rowsIndex >= rows.endIndex {
                // need to expand rows
                rows.append(contentsOf: Array(repeating: 0, count: 1 + rowsIndex - rows.endIndex ))
            }

            rows[rowsIndex] = newValue
        }
    }

    mutating func prune() {
        // This prune never occurs for the testInput. Might be able to find something else?
        if let lastFullRow = rows.lastIndex(of: ChamberRows.FullRow),
           lastFullRow > rows.startIndex {
            // keep the row before the last full row, just in case
            // I made a logic error somewhere
            let pruneDelta = lastFullRow - rows.startIndex - 1

            rows.removeFirst(pruneDelta)
            bottomRowDelta += pruneDelta
        }
    }
}


public extension BinaryInteger {
    var binaryDescription: String {
        var binaryString = ""
        var internalNumber = self
        var counter = 0

        for _ in (1...self.bitWidth) {
            binaryString.insert(contentsOf: "\(internalNumber & 1)", at: binaryString.startIndex)
            internalNumber >>= 1
            counter += 1
            if counter % 4 == 0 {
                binaryString.insert(contentsOf: " ", at: binaryString.startIndex)
            }
        }

        return binaryString
    }
}
