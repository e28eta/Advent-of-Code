import Foundation

public struct Coordinate3D: CustomStringConvertible {
    let x: Int, y: Int, z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }

    public func neighbors() -> [Coordinate3D] {
        return (-1...1).flatMap { zDelta in
            (-1...1).flatMap { yDelta in
                (-1...1).compactMap { xDelta in
                    if (zDelta == 0 && yDelta == 0 && xDelta == 0) {
                        return nil
                    }
                    return Coordinate3D(x: x + xDelta,
                                        y: y + yDelta,
                                        z: z + zDelta)
                }
            }
        }
    }

    public var description: String {
        return "(\(x),\(y),\(z))"
    }
}

public struct Grid3DIndex: Strideable, CustomStringConvertible {
    let xRange: Range<Int>
    let yRange: Range<Int>
    let zRange: Range<Int>

    let coordinate: Coordinate3D
    let index: Int

    init(x: Int, y: Int, z: Int,
         xRange: Range<Int>, yRange: Range<Int>, zRange: Range<Int>) {
        self.coordinate = Coordinate3D(x: x, y: y, z: z)

        self.xRange = xRange
        self.yRange = yRange
        self.zRange = zRange

        self.index = x - xRange.lowerBound
            + (y - yRange.lowerBound) * xRange.count
            + (z - zRange.lowerBound) * xRange.count * yRange.count
    }

    init(index: Int,
         xRange: Range<Int>, yRange: Range<Int>, zRange: Range<Int>) {
        self.index = index

        self.xRange = xRange
        self.yRange = yRange
        self.zRange = zRange

        // truncating partial x & y
        let (zQuotient, xyRemainder) = index.quotientAndRemainder(dividingBy: yRange.count * xRange.count)
        let (yQuotient, xRemainder) = xyRemainder.quotientAndRemainder(dividingBy: xRange.count)

        self.coordinate = Coordinate3D(x: xRemainder + xRange.lowerBound,
                                       y: yQuotient + yRange.lowerBound,
                                       z: zQuotient + zRange.lowerBound)
    }

    public func advanced(by n: Int) -> Self {
        return Grid3DIndex(index: index + n,
                           xRange: xRange, yRange: yRange, zRange: zRange)
    }

    public func distance(to other: Grid3DIndex) -> Int {
        return other.index - index
    }

    public var description: String {
        return coordinate.description
    }
}

public struct Grid3D<E>: RandomAccessCollection, MutableCollection {
    public typealias Element = E
    public typealias Index = Grid3DIndex

    var contents: [E]
    public let xRange: Range<Int>
    public let yRange: Range<Int>
    public let zRange: Range<Int>

    public let startIndex: Index
    public let endIndex: Index

    public init(_ contents: [[[E]]], xStart: Int = 0, yStart: Int = 0, zStart: Int = 0)  {
        let zCount = contents.count
        guard zCount > 0,
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
        zRange = (zStart..<(zStart + zCount))

        startIndex = Grid3DIndex(index: 0,
                                 xRange: xRange, yRange: yRange, zRange: zRange)
        endIndex = Grid3DIndex(index: xCount * yCount * zCount,
                               xRange: xRange, yRange: yRange, zRange: zRange)

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

    public func index(coordinate: Coordinate3D) -> Self.Index? {
        return index(x: coordinate.x,
                     y: coordinate.y,
                     z: coordinate.z)
    }

    public func index(x: Int, y: Int, z: Int) -> Self.Index? {
        guard xRange.contains(x), yRange.contains(y), zRange.contains(z) else {
            return nil
        }

        return Grid3DIndex(x: x, y: y, z: z,
                           xRange: xRange, yRange: yRange, zRange: zRange)
    }

    public subscript(coordinate: Coordinate3D) -> E? {
        get {
            return self[coordinate.x, coordinate.y, coordinate.z]
        }
    }

    public subscript(x: Int, y: Int, z: Int) -> E? {
        get {
            return index(x: x, y: y, z: z).map { contents[$0.index] }
        }
    }
}

extension Grid3D: CustomStringConvertible where Grid3D.Element: CustomStringConvertible {
    public var description: String {
        return zRange.map { z in
            yRange.map { y in
                xRange.map { x in
                    String(describing: self[x, y, z]!)
                }.joined()
            }.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}

