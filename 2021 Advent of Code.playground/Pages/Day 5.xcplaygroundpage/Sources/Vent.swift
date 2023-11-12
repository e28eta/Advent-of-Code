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

    public var points: [Point] {
        guard isHorizontalOrVertical else { return [] }

        if start.x == end.x {
            return stride(between: start.y,
                          and: end.y,
                          by: 1)
            .map { y in
                Point(x: start.x, y: y)
            }
        } else { //
            return stride(between: start.x,
                          and: end.x,
                          by: 1).map { x in
                Point(x: x, y: start.y)
            }
        }
    }
}

public struct Vents {
    let lines: [Line]

    public init(_ string: String) {
        lines = string.lines().compactMap(Line.init)
    }

    public func numberPlacesWithOverlaps() -> Int {
        return lines
            .flatMap { $0.points }
            .reduce(into: [:]) { d, point in
                d[point, default: 0] += 1
            }
            .values
            .filter { $0 >= 2 }
            .count
    }
}
