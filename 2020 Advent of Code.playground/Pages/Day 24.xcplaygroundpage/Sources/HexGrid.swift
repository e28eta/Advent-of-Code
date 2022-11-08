import Foundation

public struct HexGrid<Element: Hashable> {
    var currentState: [Point: Element] = [:]

    public init() { }

    public subscript(_ point: Point, default defaultElement: @autoclosure () -> Element) -> Element {
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
}
