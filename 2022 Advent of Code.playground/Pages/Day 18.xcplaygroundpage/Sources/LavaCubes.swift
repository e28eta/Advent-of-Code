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
                                 xRange: (minX ..< (maxX + 1)),
                                 yRange: (minY ..< (maxY + 1)),
                                 zRange: (minZ ..< (maxZ + 1)))
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
}
