import Foundation
import RegexBuilder

public func part1(_ string: String, y: Int) -> Int {
    let sensors = Sensor.sensors(from: string)
    var positionsCovered = sensors
        .compactMap { sensor in sensor.coverageOf(y: y) }
        .reduce(into: Set<Int>()) { set, coverage in
            set.formUnion(coverage)
        }

    for beacon in sensors.map(\.closestBeacon) {
        if beacon.y == y {
            positionsCovered.remove(beacon.x)
        }
    }

    return positionsCovered.count
}

public func part2(_ string: String, bounds: ClosedRange<Int>) -> Int {
    let sensors = Sensor.sensors(from: string)

    // same approach as part1, just brute forcing every row?
    // cleaned up my memory usage (not a set of each column), since
    // there's only supposed to be one result.
    // Almost sad that brute force worked for me, some good solutions
    // on reddit: like brute force checking only squares +1 past detection range,
    // or the fact it'll be the single square in the middle of a 4-way
    // intersection of the edges of detection
    for y in bounds {
        let sortedRanges = sensors
            .compactMap { sensor in sensor.coverageOf(y: y) }
            .sorted(using: KeyPathComparator(\.lowerBound))

        var x = bounds.lowerBound
        for coverage in sortedRanges {
            if x + 1 < coverage.lowerBound && bounds.contains(coverage.lowerBound) {
                // gap in coverage!
                return (x + 1) * 4_000_000 + y
            }
            x = max(x, coverage.upperBound)
        }
    }

    return 0
}

public struct Sensor {
    public let location: Point
    public let closestBeacon: Point

    public init(location: Point, closestBeacon: Point) {
        self.location = location
        self.closestBeacon = closestBeacon
    }

    public func coverageOf(y targetY: Int) -> ClosedRange<Int>? {
        let coverageDistance = location.manhattanDistance(to: closestBeacon)
        let closestPointOnTarget = Point(x: location.x, y: targetY)
        let verticalDistanceToY = location.manhattanDistance(to: closestPointOnTarget)

        if verticalDistanceToY > coverageDistance {
            // too far away, zero coverage
            return nil
        }

        let overlapRange = coverageDistance - verticalDistanceToY
        return (location.x - overlapRange) ... (location.x + overlapRange)
    }
}

extension Sensor: CustomStringConvertible {
    public var description: String {
        return "sensor at \(location) detecting \(closestBeacon)"
    }
}

let EnglishLocale = Locale(identifier: "en-US")

extension Sensor {
    static let SensorXRef = Reference<Int>()
    static let SensorYRef = Reference<Int>()
    static let BeaconXRef = Reference<Int>()
    static let BeaconYRef = Reference<Int>()

    static let MatchingRegex = Regex {
        Anchor.startOfLine
        "Sensor at x="
        Capture(.localizedInteger(locale: EnglishLocale), as: SensorXRef)
        ", y="
        Capture(.localizedInteger(locale: EnglishLocale), as: SensorYRef)
        ": closest beacon is at x="
        Capture(.localizedInteger(locale: EnglishLocale), as: BeaconXRef)
        ", y="
        Capture(.localizedInteger(locale: EnglishLocale), as: BeaconYRef)
        Optionally(.newlineSequence)
    }

    public static func sensors(from string: String) -> [Sensor] {
        return string.matches(of: MatchingRegex).map { match in
            Sensor(location: Point(x: match[SensorXRef],
                                   y: match[SensorYRef]),
                   closestBeacon: Point(x: match[BeaconXRef],
                                        y: match[BeaconYRef]))
        }
    }
}
