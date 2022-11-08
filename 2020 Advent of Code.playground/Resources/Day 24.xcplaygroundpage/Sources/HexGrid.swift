import Foundation

public protocol Flippable {
    mutating func flip()
}

public struct HexGrid<Element: Hashable & Flippable> {
    public var currentState: [HexCoordinate: Element] = [:]

    public init() { }

    public init(input: String, defaultValue: Element) {
        let points = try! input.split(separator: "\n").map(HexCoordinate.init)

        for p in points {
            currentState[p, default: defaultValue].flip()
        }
    }

    public subscript(_ point: HexCoordinate, default defaultElement: @autoclosure () -> Element) -> Element {
        get {
            return currentState[point, default: defaultElement()]
        }
        set(newValue) {
            currentState[point] = newValue
        }
    }

    public func visitedStates(_ matching: (Element) -> Bool) -> [Element] {
        return currentState.values.filter(matching)
    }

    public func bounds() -> (x: Range<Int>, y: Range<Int>) {
        var minX = 0, minY = 0, maxX = 0, maxY = 0

        for currentKey in currentState.keys {
            minX = min(minX, currentKey.x)
            minY = min(minY, currentKey.y)
            maxX = max(maxX, currentKey.x)
            maxY = max(maxY, currentKey.y)
        }

        return (x: minX ..< maxX + 1, y: minY ..< maxY + 1)
    }

    public func validCoordinates() -> AnySequence<HexCoordinate> {
        // big area covering anything with a explicitly set state
        var (xRange, yRange) = bounds()
        // expand to all tiles w/in one neighbor step
        xRange = xRange.expand(lower: 2, upper: 2)
        yRange = yRange.expand(lower: 1, upper: 1)

        print("coordinates span \(xRange) and \(yRange)")

        return AnySequence {
            var iterator = yRange
                .lazy
                .reversed()
                .flatMap { currentY in
                    let yModulo2 = currentY % 2
                    return xRange
                        .lazy
                        .filter { $0 % 2 == yModulo2 }
                        .map({ HexCoordinate(x: $0, y: currentY) })
                }
                .makeIterator()

            return AnyIterator { return iterator.next() }
        }
    }
}

extension HexGrid where Element: CustomStringConvertible & ConwayRule {
    public var description: String {
        let (xRange, yRange) = bounds()

        return xRange
            .map(\.description)
            .joined(separator: "\t")
        + yRange
            .reversed()
            .map { currentY in
                let yModulo2 = currentY % 2
                
                return currentY.description + "\t" + xRange
                    .map { currentX in
                        if currentX % 2 == yModulo2 {
                            return currentState[HexCoordinate(x: currentX, y: currentY),
                                                default: Element.defaultValue()].description
                        } else {
                            return " "
                        }
                    }
                    .joined(separator: "\t")
            }
            .joined(separator: "\n")
    }
}

extension HexGrid where Element: ConwayRule {
    public mutating func step() {
        let originalState = currentState
        let elementDefaultValue = Element.defaultValue()

        for coordinate in validCoordinates() {
            let neighbors = coordinate.neighbors()
                .map { originalState[$0, default: elementDefaultValue] }
            let coordState = originalState[coordinate, default: elementDefaultValue]

            var didChange = false
            if coordState.shouldChange(neighbors: neighbors) {
                didChange = true
                currentState[coordinate] = coordState.changedValue()
            }
            print(coordinate, coordState, didChange ? "⇾ \(currentState[coordinate]!)" : "\t", neighbors)
        }

        // trim the state, getting rid of any default value entries
        currentState = currentState.filter { entry in
            entry.value != elementDefaultValue
        }
    }
}
