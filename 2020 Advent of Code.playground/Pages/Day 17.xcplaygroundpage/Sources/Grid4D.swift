import Foundation

public struct Coordinate4D: CustomStringConvertible {
    let x: Int, y: Int, z: Int, w: Int

    public init(x: Int, y: Int, z: Int, w: Int) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public func neighbors() -> [Coordinate4D] {
        return (-1...1).flatMap { wDelta in
            (-1...1).flatMap { zDelta in
                (-1...1).flatMap { yDelta in
                    (-1...1).compactMap { xDelta in
                        if (wDelta == 0 && zDelta == 0 && yDelta == 0 && xDelta == 0) {
                            return nil
                        }
                        return Coordinate4D(x: x + xDelta,
                                            y: y + yDelta,
                                            z: z + zDelta,
                                            w: w + wDelta)
                    }
                }
            }
        }
    }

    public var description: String {
        return "(\(x),\(y),\(z),\(w))"
    }
}

public struct Grid4DIndex: Strideable, CustomStringConvertible {
    let xRange: Range<Int>
    let yRange: Range<Int>
    let zRange: Range<Int>
    let wRange: Range<Int>

    let coordinate: Coordinate4D
    let index: Int

    init(x: Int, y: Int, z: Int, w: Int,
         xRange: Range<Int>, yRange: Range<Int>, zRange: Range<Int>, wRange: Range<Int>) {
        self.coordinate = Coordinate4D(x: x, y: y, z: z, w: w)

        self.xRange = xRange
        self.yRange = yRange
        self.zRange = zRange
        self.wRange = wRange

        self.index = x - xRange.lowerBound
            + (y - yRange.lowerBound) * xRange.count
            + (z - zRange.lowerBound) * xRange.count * yRange.count
            + (w - wRange.lowerBound) * xRange.count * yRange.count * zRange.count
    }

    init(index: Int,
         xRange: Range<Int>, yRange: Range<Int>, zRange: Range<Int>, wRange: Range<Int>) {
        self.index = index

        self.xRange = xRange
        self.yRange = yRange
        self.zRange = zRange
        self.wRange = wRange

        let (wQuotient, xyzRemainder) = index.quotientAndRemainder(dividingBy: zRange.count * yRange.count * xRange.count)
        let (zQuotient, xyRemainder) = xyzRemainder.quotientAndRemainder(dividingBy: yRange.count * xRange.count)
        let (yQuotient, xRemainder) = xyRemainder.quotientAndRemainder(dividingBy: xRange.count)

        self.coordinate = Coordinate4D(x: xRemainder + xRange.lowerBound,
                                       y: yQuotient + yRange.lowerBound,
                                       z: zQuotient + zRange.lowerBound,
                                       w: wQuotient + wRange.lowerBound)
    }

    public func advanced(by n: Int) -> Self {
        return Grid4DIndex(index: index + n,
                           xRange: xRange, yRange: yRange, zRange: zRange, wRange: wRange)
    }

    public func distance(to other: Grid4DIndex) -> Int {
        return other.index - index
    }

    public var description: String {
        return coordinate.description
    }
}

public struct Grid4D<E>: RandomAccessCollection, MutableCollection {
    public typealias Element = E
    public typealias Index = Grid4DIndex

    var contents: [E]
    public let xRange: Range<Int>
    public let yRange: Range<Int>
    public let zRange: Range<Int>
    public let wRange: Range<Int>

    public let startIndex: Index
    public let endIndex: Index

    public init(_ contents: [[[[E]]]], xStart: Int = 0, yStart: Int = 0, zStart: Int = 0, wStart: Int = 0)  {
        let wCount = contents.count
        guard let zCount = contents.first?.count,
              zCount > 0,
              let yCount = contents.first?.first?.count,
              yCount > 0,
              let xCount = contents.first?.first?.first?.count,
              xCount > 0 else {
            fatalError("Must be non-empty grid")
        }

        let areAllArraysSameSize = contents.allSatisfy { cube in
            cube.count == zCount && cube.allSatisfy { plane in
                plane.count == yCount && plane.allSatisfy({ row in
                    row.count == xCount
                })
            }
        }
        guard areAllArraysSameSize else {
            fatalError("Every array must be the same size as its counterparts")
        }

        xRange = (xStart..<(xStart + xCount))
        yRange = (yStart..<(yStart + yCount))
        zRange = (zStart..<(zStart + zCount))
        wRange = (wStart..<(wStart + wCount))

        startIndex = Grid4DIndex(index: 0,
                                 xRange: xRange, yRange: yRange, zRange: zRange, wRange: wRange)
        endIndex = Grid4DIndex(index: xCount * yCount * zCount * wCount,
                               xRange: xRange, yRange: yRange, zRange: zRange, wRange: wRange)

        self.contents = contents.flatMap { cube in
            cube.flatMap { plane in
                plane.flatMap { row in
                    row
                }
            }
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

    public func index(coordinate: Coordinate4D) -> Self.Index? {
        return index(x: coordinate.x,
                     y: coordinate.y,
                     z: coordinate.z,
                     w: coordinate.w)
    }

    public func index(x: Int, y: Int, z: Int, w: Int) -> Self.Index? {
        guard xRange.contains(x), yRange.contains(y), zRange.contains(z), wRange.contains(w) else {
            return nil
        }

        return Grid4DIndex(x: x, y: y, z: z, w: w,
                           xRange: xRange, yRange: yRange, zRange: zRange, wRange: wRange)
    }

    public subscript(coordinate: Coordinate4D) -> E? {
        get {
            return self[coordinate.x, coordinate.y, coordinate.z, coordinate.w]
        }
    }

    public subscript(x: Int, y: Int, z: Int, w: Int) -> E? {
        get {
            return index(x: x, y: y, z: z, w: w).map { contents[$0.index] }
        }
    }
}

extension Grid4D: CustomStringConvertible where Grid4D.Element: CustomStringConvertible {
    public var description: String {
        return wRange.map { w in
            zRange.map { z in
                return "z=\(z), w=\(w)\n" + yRange.map { y in
                    xRange.map { x in
                        String(describing: self[x, y, z, w]!)
                    }.joined()
                }.joined(separator: "\n")
            }.joined(separator: "\n\n")
        }.joined(separator: "\n\n")
    }
}
