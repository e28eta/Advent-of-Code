import Foundation

public struct Coordinate2D: Hashable {
    let x: Int, y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func manhattanDistance(to other: Coordinate2D) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }
}

public struct Coordinate2DTime: CustomStringConvertible, Hashable {
    let x: Int, y: Int, t: Int

    public init(x: Int, y: Int, t: Int) {
        self.x = x
        self.y = y
        self.t = t
    }

    public func neighbors() -> [Coordinate2DTime] {
        // up, down, left, right, or wait
        let deltas = [
            (0, -1),
            (0, 1),
            (-1, 0),
            (1, 0),
            (0, 0),
        ]

        return deltas.map { (dx, dy) in
            // time always flows forward
            Coordinate2DTime(x: x + dx, y: y + dy, t: t + 1)
        }
    }

    public func withoutTime() -> Coordinate2D {
        return Coordinate2D(x: x, y: y)
    }

    public var description: String {
        return "(\(x),\(y),\(t))"
    }

    static func ==(_ lhs: Coordinate2DTime, _ rhs: Coordinate2D) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

public struct Grid2DTimeIndex: Strideable, CustomStringConvertible {
    let xRange: Range<Int>
    let yRange: Range<Int>
    let tRange: Range<Int>

    public let coordinate: Coordinate2DTime
    let index: Int

    init(x: Int, y: Int, t: Int,
         xRange: Range<Int>, yRange: Range<Int>, tRange: Range<Int>) {
        self.coordinate = Coordinate2DTime(x: x, y: y, t: t)

        self.xRange = xRange
        self.yRange = yRange
        self.tRange = tRange

        self.index = x - xRange.lowerBound
        + (y - yRange.lowerBound) * xRange.count
        + (t - tRange.lowerBound) * xRange.count * yRange.count
    }

    init(index: Int,
         xRange: Range<Int>, yRange: Range<Int>, tRange: Range<Int>) {
        self.index = index

        self.xRange = xRange
        self.yRange = yRange
        self.tRange = tRange

        // truncating partial x & y
        let (tQuotient, xyRemainder) = index.quotientAndRemainder(dividingBy: yRange.count * xRange.count)
        let (yQuotient, xRemainder) = xyRemainder.quotientAndRemainder(dividingBy: xRange.count)

        self.coordinate = Coordinate2DTime(x: xRemainder + xRange.lowerBound,
                                           y: yQuotient + yRange.lowerBound,
                                           t: tQuotient + tRange.lowerBound)
    }

    public func advanced(by n: Int) -> Self {
        return Grid2DTimeIndex(index: index + n,
                               xRange: xRange,
                               yRange: yRange,
                               tRange: tRange)
    }

    public func distance(to other: Grid2DTimeIndex) -> Int {
        return other.index - index
    }

    public var description: String {
        return coordinate.description
    }
}

public struct Grid2DTime<E>: RandomAccessCollection, MutableCollection {
    public typealias Element = E
    public typealias Index = Grid2DTimeIndex

    var contents: [E]
    public let xRange: Range<Int>
    public let yRange: Range<Int>
    public let tRange: Range<Int>

    public let startIndex: Index
    public let endIndex: Index

    public init(xRange: Range<Int>, yRange: Range<Int>, tRange: Range<Int>, element: (Int, Int, Int) -> Element) {
        let totalCount = xRange.count * yRange.count * tRange.count

        let startIndex = Grid2DTimeIndex(index: 0,
                                     xRange: xRange,
                                     yRange: yRange,
                                     tRange: tRange)

        let endIndex = Grid2DTimeIndex(index: totalCount,
                                   xRange: xRange,
                                   yRange: yRange,
                                   tRange: tRange)

        self.contents = Array(unsafeUninitializedCapacity: totalCount, initializingWith: { buffer, initializedCount in
            for index in startIndex ..< endIndex {
                buffer[index.index] = element(index.coordinate.x, index.coordinate.y, index.coordinate.t)
            }
            initializedCount = totalCount
        })

        self.xRange = xRange
        self.yRange = yRange
        self.tRange = tRange

        self.startIndex = startIndex
        self.endIndex = endIndex
    }

    public init(repeating defaultElement: E, xRange: Range<Int>, yRange: Range<Int>, tRange: Range<Int>) {
        let totalCount = xRange.count * yRange.count * tRange.count

        self.contents = Array(repeating: defaultElement,
                              count: totalCount)
        self.xRange = xRange
        self.yRange = yRange
        self.tRange = tRange

        startIndex = Grid2DTimeIndex(index: 0,
                                     xRange: xRange,
                                     yRange: yRange,
                                     tRange: tRange)

        endIndex = Grid2DTimeIndex(index: totalCount,
                                   xRange: xRange,
                                   yRange: yRange,
                                   tRange: tRange)
    }

    public init(_ contents: [[[E]]], xStart: Int = 0, yStart: Int = 0, tStart: Int = 0)  {
        let tCount = contents.count
        guard tCount > 0,
              let yCount = contents.first?.count,
              yCount > 0,
              let xCount = contents.first?.first?.count,
              xCount > 0 else {
            fatalError("Must be non-empty grid")
        }

        let areAllArraysSameSize = contents.allSatisfy { plane in
            plane.count == yCount && plane.allSatisfy({ row in
                row.count == xCount
            })
        }
        guard areAllArraysSameSize else {
            fatalError("Every array must be the same size as its counterparts")
        }

        xRange = (xStart..<(xStart + xCount))
        yRange = (yStart..<(yStart + yCount))
        tRange = (tStart..<(tStart + tCount))

        startIndex = Grid2DTimeIndex(index: 0,
                                     xRange: xRange, yRange: yRange, tRange: tRange)
        endIndex = Grid2DTimeIndex(index: xCount * yCount * tCount,
                                   xRange: xRange, yRange: yRange, tRange: tRange)

        self.contents = contents.flatMap { arrayOfArrays in
            arrayOfArrays.flatMap { $0 }
        }
    }

    public subscript(position: Index) -> E {
        get {
            contents[position.index]
        }
        set(newValue) {
            contents[position.index] = newValue
        }
    }

    public func index(coordinate: Coordinate2DTime) -> Self.Index? {
        return index(x: coordinate.x,
                     y: coordinate.y,
                     t: coordinate.t)
    }

    public func index(x: Int, y: Int, t: Int) -> Self.Index? {
        guard xRange.contains(x), yRange.contains(y) else {
            return nil
        }

        // Loop `t` through tRange
        return Grid2DTimeIndex(x: x, y: y, t: (t % tRange.count) + tRange.lowerBound,
                               xRange: xRange, yRange: yRange, tRange: tRange)
    }

    public subscript(coordinate: Coordinate2DTime) -> E? {
        get {
            return self[coordinate.x, coordinate.y, coordinate.t]
        }
    }

    public subscript(x: Int, y: Int, t: Int) -> E? {
        get {
            return index(x: x, y: y, t: t).map { contents[$0.index] }
        }
    }

    public func neighbors(of index: Index) -> [Index] {
        let coordinate = index.coordinate

        return coordinate.neighbors().compactMap(index(coordinate:))
    }
}

extension Grid2DTime: CustomStringConvertible where Grid2DTime.Element: CustomStringConvertible {
    public var description: String {
        return tRange.map { t in
            yRange.map { y in
                xRange.map { x in
                    String(describing: self[x, y, t]!)
                }.joined()
            }.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}

