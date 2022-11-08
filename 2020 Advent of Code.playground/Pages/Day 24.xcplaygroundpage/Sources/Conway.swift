import Foundation

public protocol ConwayRule {
    func shouldChange(neighbors: [Self]) -> Bool
    func changedValue() -> Self

    static func defaultValue() -> Self
}

