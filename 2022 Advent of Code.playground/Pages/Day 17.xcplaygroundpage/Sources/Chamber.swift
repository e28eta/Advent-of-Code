import Foundation

public enum WindDirection: Character {
    case left = "<"
    case right = ">"

    public static func windPattern(_ string: String) -> some Sequence<WindDirection> {
        return string.compactMap({ WindDirection(rawValue: $0) }).cycled()
    }
}

extension WindDirection: CustomStringConvertible {
    public var description: String { return String(rawValue) }
}

enum Shape {
    static let Count = 2022
    case hyphen, plus, ell, pipe, square

    static func sequence() -> some Sequence<Shape> {
        return [Shape.hyphen, .plus, .ell, .pipe, .square]
            .cycled()
            .prefix(Shape.Count) // seems like a fine spot to limit
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

    var rows = Array<Row>(repeating: 0,
                          count: Shape.Count * 4 + 10) // not a crazy amount, just pre-allocate needed space

    public init() { }

    public mutating func part1(wind: some Sequence<WindDirection>, count: Int = 2022) -> Int {
        var rockAppearanceRow = Chamber.rockAppearanceDelta
        var wind = wind.makeIterator()

        for shapeEnum in Shape.sequence().prefix(count) {
            var bottomOfShape = rockAppearanceRow + 1 // due to shape of repeat/while loop
            var shape = shapeEnum.bitwise()

            repeat {
                bottomOfShape -= 1
                shape = shift(shape: shape, wind.next()!, on: bottomOfShape)
            } while canDrop(shape, to: bottomOfShape - 1)

            settle(rock: shape, at: bottomOfShape)

            let topOfShape = bottomOfShape + shape.count
            rockAppearanceRow = max(rockAppearanceRow,
                                    topOfShape + Chamber.rockAppearanceDelta)
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
            fatalError("Found collision during settling:\n\(shape)\n\(rows[(bottomRowIdx...(bottomRowIdx + 5))])")
        }

        for (shapeIdx, chamberIdx) in indices {
            rows[chamberIdx] |= shape[shapeIdx]
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
