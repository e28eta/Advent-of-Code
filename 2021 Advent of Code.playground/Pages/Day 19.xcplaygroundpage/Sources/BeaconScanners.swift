import Foundation

public struct Point3D: Hashable {
    public let x: Int
    public let y: Int
    public let z: Int

    init(_ string: some StringProtocol) {
        let components = string.components(separatedBy: ",")
        let nums = components.compactMap(Int.init)
        guard nums.count == 3 else {
            fatalError("invalid input '\(string)'")
        }
        self.x = nums[0]
        self.y = nums[1]
        self.z = nums[2]
    }

    public func manhattanDistance(to other: Point3D) -> Int {
        return abs(x - other.x) + abs(y - other.y) + abs(z - other.z)
    }
}

public struct BeaconScanner {
    public let id: Int
    public let beacons: [Point3D]
    public let perBeaconDistances: [Set<Int>]

    // "fingerprints" beacon cloud. There are geometries where
    // a set wouldn't work, since it drops dupe distances, but
    // I want fast intersection
    public let allInterbeaconDistances: Set<Int>

    public init(_ string: some StringProtocol) {
        let lines = string.lines()

        guard lines.count > 1,
              let match = try? /--- scanner (\d+) ---/.firstMatch(in: lines[0]),
              let id = Int(match.1) else {
            fatalError("invalid scanner")
        }
        let beacons = lines.dropFirst(1).map(Point3D.init)

        self.id = id
        self.beacons = beacons

        let perBeaconDistances = beacons.map { beacon in
            beacons.reduce(into: Set()) { set, other in
                // includes "bonus" entry of distance zero, whatever
                set.insert(beacon.manhattanDistance(to: other))
            }
        }

        self.perBeaconDistances = perBeaconDistances
        self.allInterbeaconDistances = perBeaconDistances
            .reduce(into: Set()) { set, dist in
                set.formUnion(dist)
            }
    }

    public func overlapScore(with other: BeaconScanner) -> Int {
        return allInterbeaconDistances
            .intersection(other.allInterbeaconDistances)
            .count
    }

    public func matchingBeacons(with other: BeaconScanner) -> some Collection<(Int, Int)> {
        // just do N^2 all comparisons
        let possiblePairs = beacons.indices
            .flatMap { idx in
                other.beacons.indices
                    .map { jdx in
                        (idx, jdx, perBeaconDistances[idx]
                            .intersection(other.perBeaconDistances[jdx])
                            .count)
                    }
                    .filter { $0.2 > 11 }
            }
            .sorted { left, right in
                return left.2 > right.2
            }

        var myRemainingBeacons = Set(beacons.indices)
        var theirRemainingBeacons = Set(other.beacons.indices)
        // go through the pairs, and as long as this is the best candidate
        // so far, put it into the results and remember that it's been
        // returned

        return possiblePairs.filter {
            let (idx, jdx, _) = $0

            if myRemainingBeacons.contains(idx) && theirRemainingBeacons.contains(jdx) {
                myRemainingBeacons.remove(idx)
                theirRemainingBeacons.remove(jdx)

                return true
            }
            return false
        }
        .map {
            ($0.0, $0.1)
        }
    }

    public func nonUniqueMatchingBeacons(with other: BeaconScanner) -> some Collection<(Int, Int, Int)> {
        // just do N^2 all comparisons
        return beacons.indices
            .flatMap { idx in
                other.beacons.indices
                    .map { jdx in
                        (idx, jdx, perBeaconDistances[idx]
                            .intersection(other.perBeaconDistances[jdx])
                            .count)
                    }
                    .filter { $0.2 > 11 }
            }
            .sorted { left, right in
                return left.2 > right.2
            }
    }
}
