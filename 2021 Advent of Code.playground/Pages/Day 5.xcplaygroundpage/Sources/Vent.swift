import Foundation

struct Line {
    let start: Point
    let end: Point

    init?(_ line: String) {
        guard let (startStr, endStr) = line.splitOnce(separator: " -> "),
              let start = Point(startStr),
              let end = Point(endStr) else {
            return nil
        }

        self.start = start
        self.end = end
    }

    var isHorizontalOrVertical: Bool {
        return start.x == end.x || start.y == end.y
    }

    public func points(allowingDiagonal: Bool = false) -> [Point] {
        guard isHorizontalOrVertical || allowingDiagonal else { return [] }

        let xStride = stride(from: start.x,
                             through: end.x,
                             by: start.x <= end.x ? 1 : -1)
        let yStride = stride(from: start.y,
                             through: end.y,
                             by: start.y <= end.y ? 1 : -1)

        if start.x == end.x {
            return yStride.map { y in
                Point(x: start.x, y: y)
            }
        } else if start.y == end.y {
            return xStride.map { x in
                Point(x: x, y: start.y)
            }
        } else {
            return zip(xStride, yStride).map(Point.init)
        }
    }
}

public struct Vents {
    let lines: [Line]

    public init(_ string: String) {
        lines = string.lines().compactMap(Line.init)
    }

    public func numberPlacesWithOverlaps(allowingDiagonals: Bool = false) -> Int {
        return lines
            .flatMap { $0.points(allowingDiagonal: allowingDiagonals) }
            .reduce(into: [:]) { d, point in
                d[point, default: 0] += 1
            }
            .values
            .filter { $0 >= 2 }
            .count
    }
}
