import Foundation

public struct LavaCubes {
    public let dropletGrid: Grid3D<Bool>
    public let exposedSurfaceArea: Int

    public init(_ string: String) {
        let scannedCoordinates = string.lines().compactMap(Coordinate3D.init)

        guard !scannedCoordinates.isEmpty else {
            // no coords, grid is empty!
            dropletGrid = Grid3D(repeating: false,
                                 xRange: 0..<0,
                                 yRange: 0..<0,
                                 zRange: 0..<0)
            exposedSurfaceArea = 0
            return
        }

        let (minX, maxX) = scannedCoordinates.map(\.x).minAndMax()!
        let (minY, maxY) = scannedCoordinates.map(\.y).minAndMax()!
        let (minZ, maxZ) = scannedCoordinates.map(\.z).minAndMax()!

        var dropletGrid = Grid3D(repeating: false,
                                 xRange: ((minX - 1) ..< (maxX + 2)),
                                 yRange: ((minY - 1) ..< (maxY + 2)),
                                 zRange: ((minZ - 1) ..< (maxZ + 2)))
        var exposedSurfaceArea = 0

        for coordinate in scannedCoordinates {
            guard let gridIndex = dropletGrid.index(coordinate: coordinate) else {
                fatalError("coordinate outside of grid? \(coordinate)")
            }
            guard dropletGrid[gridIndex] == false else {
                fatalError("repeated coordinate? \(coordinate)")
            }

            dropletGrid[gridIndex] = true
            let coveredSideCount = coordinate
                .neighbors()
            // some neighbors might not be in the grid, they'll never be covered
                .compactMap(dropletGrid.index(coordinate:))
                .filter { dropletGrid[$0] }
                .count

            exposedSurfaceArea += 6 - (2 * coveredSideCount)
        }

        self.dropletGrid = dropletGrid
        self.exposedSurfaceArea = exposedSurfaceArea
    }

    public func part2() -> Int {
        // maybe some sort of graph algorithm, and finding out faces
        // that are reachable from outside? I can expand the ranges
        // so that the outer surface is a guaranteed contiguous
        // shape, and then a search along each neighbor?
        // 6 neighbors: if lava then +1, if not: ensure visit it
        // exactly once

        var outerSurfaceArea = 0
        // since I expanded the range, this is guaranteed air
        var coordinatesToVisit = [dropletGrid.startIndex.coordinate]
        var allAirCoords: Set = [coordinatesToVisit[0]]

        while let nextCoordinate = coordinatesToVisit.popLast() {
            for neighborIndex in nextCoordinate.neighbors().compactMap(dropletGrid.index(coordinate:)) {
                if dropletGrid[neighborIndex] {
                    // found a surface
                    outerSurfaceArea += 1
                    continue
                }

                // neighbor has air
                let neighborCoord = neighborIndex.coordinate
                if !allAirCoords.contains(neighborCoord) {
                    // we haven't seen this neighbor yet. Record that
                    // we've seen it, and queue it for visiting
                    allAirCoords.insert(neighborCoord)
                    coordinatesToVisit.append(neighborCoord)
                }
            }
        }

        return outerSurfaceArea
    }
}
