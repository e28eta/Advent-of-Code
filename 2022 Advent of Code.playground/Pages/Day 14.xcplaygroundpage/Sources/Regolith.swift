import Foundation

enum PhysicalElement: String, CustomStringConvertible {
    case air = ".", sand = "o", rock = "#", source = "+"

    var description: String { return self.rawValue }

    func canContainSand() -> Bool {
        switch self {
        case .air, .source:
            return true
        case .sand, .rock:
            return false
        }
    }
}

enum SandConnectivity: NeighborConnectivity {
    case leftFirst

    func possibleNeighbors() -> any Sequence<(Int, Int)> {
        return [
            // down
            (1, 0),
            // down left
            (1, -1),
            // down right
            (1, 1)
        ]
    }
}

public struct Cave {
    var grid: Grid<PhysicalElement>
    let bounds: CaveBounds
    let source: GridIndex

    public init(_ string: String) {
        let rockPoints = string.lines()
            .map { line in
                line.components(separatedBy: " -> ")
                    .compactMap(Point.init)
            }

        let bounds = CaveBounds.bounds(from: rockPoints)
        let xElements = Array<PhysicalElement>(repeating: .air, count: bounds.xRange.count)
        let yElements = Array<[PhysicalElement]>(repeating: xElements, count: bounds.yRange.count)
        var grid = Grid(yElements, connectivity: SandConnectivity.leftFirst)

        self.source = bounds.sourceIndex()
        grid[self.source] = .source

        // fill in the rock squares
        for path in rockPoints {
            Point.points(along: path)
                .compactMap { bounds.index(of: $0) }
                .forEach { index in
                    grid[index] = .rock
                }
        }

        let lastRow = grid.contents.endIndex -  1
        for colIdx in grid.contents[lastRow].indices {
            grid.contents[lastRow][colIdx] = .rock
        }

        self.grid = grid
        self.bounds = bounds
    }

    public mutating func part1() -> Int {
        for grain in (1...) {
            let destination = dropSand(from: source)
            grid[destination] = .sand

            // fell onto the floor, don't count this one
            if destination.row == (grid.height - 2) {
                return grain - 1
            }
        }

        return -1
    }

    public mutating func part2() -> Int {
        for grain in (1...) {
            let destination = dropSand(from: source)
            grid[destination] = .sand

            // fell into the source of the sand
            if destination == bounds.sourceIndex() {
                return grain
            }
        }

        return -1
    }

    func dropSand(from index: GridIndex) -> GridIndex {
        guard self.grid[index].canContainSand() else {
            fatalError("cannot drop sand from \(index) with contents \(self.grid[index])")
        }

        for neighbor in self.grid.neighbors(of: index) {
            if case .air = self.grid[neighbor] {
                return dropSand(from: neighbor)
            }
        }

        // none of the lower spaces had room, put it here
        return index
    }
}

extension Cave: CustomStringConvertible {
    public var description: String {
        return grid.contents.map { row in
            row.map(\.rawValue).joined()
        }.joined(separator: "\n")
    }
}

public struct Point: CustomStringConvertible {
    public var x: Int, y: Int

    public init(x: Int, y: Int) { self.x = x; self.y = y }
    public init(_ s: String) {
        let components = s.split(separator: ",")
        x = Int(components[0])!
        y = Int(components[1])!
    }
    public var description: String { return "(\(x), \(y))" }

    static func points(along path: [Point]) -> [Point] {
        return zip(path, path.dropFirst())
            .flatMap { (first, second) in
                let points: any Sequence<(Int, Int)>

                if first.y == second.y {
                    // stride along X, same Y every time
                    let xPoints = stride(from: min(first.x, second.x),
                                     through: max(first.x, second.x),
                                     by: 1)
                    let yPoints = sequence(first: first.y) { $0 }

                    points = zip(xPoints, yPoints)
                } else if first.x == second.x {
                    // same X every time, stride along Y
                    let xPoints = sequence(first: first.x) { $0 }
                    let yPoints = stride(from: min(first.y, second.y),
                                     through: max(first.y, second.y),
                                     by: 1)

                    points = zip(xPoints, yPoints)
                } else {
                    fatalError("Both X and Y are changing along this path segment \(first) -> \(second)")
                }

                return points.map { Point(x: $0.0, y: $0.1) }
            }
    }
}

struct CaveBounds {
    static let source = Point(x: 500, y: 0)

    // Ensure it contains the source
    var minX: Int = source.x, maxX: Int = source.x
    var minY: Int = source.y, maxY: Int = source.y

    var xRange: ClosedRange<Int> {
        return (minX ... maxX)
    }
    var yRange: ClosedRange<Int> {
        return (minY ... maxY)
    }

    static func bounds(from points: [[Point]]) -> CaveBounds {
        var result = points.flatMap({$0}).reduce(into: CaveBounds()) { bounds, point in
            bounds.minX = min(point.x, bounds.minX)
            bounds.minY = min(point.y, bounds.minY)

            bounds.maxX = max(point.x, bounds.maxX)
            bounds.maxY = max(point.y, bounds.maxY)
        }

        // room for the floor
        result.maxY += 2
        
        // room for horizontal expansion
        let maxSandHeight = (result.maxY - source.y)

        result.minX = min(result.minX, source.x - maxSandHeight)
        result.maxX = max(result.maxX, source.x + maxSandHeight)

        return result
    }

    func index(of point: Point) -> GridIndex? {
        return GridIndex(width: xRange.count,
                         row: point.y - minY,
                         col: point.x - minX)
    }

    func sourceIndex() -> GridIndex {
        return index(of: CaveBounds.source)! // guaranteed to contain, when constructed through this class
    }
}


