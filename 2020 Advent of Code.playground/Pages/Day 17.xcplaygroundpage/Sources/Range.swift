import Foundation

public extension Range where Bound: Strideable {
    /**
     Returns a larger range: lowering the lowerBound and raising the upperBound, by the amounts
     provided, which should be positive.
     */
    func expand(lower: Bound.Stride? = nil, upper: Bound.Stride? = nil) -> Self {
        return (lower.map { lowerBound.advanced(by: -1 * $0)} ?? lowerBound)
            ..<
            (upper.map { upperBound.advanced(by: $0)} ?? upperBound)
    }
    
    /**
     Returns a smaller range: raising the lowerBound and lowering the upperBound, by the amounts
     provided, which should be positive.
     */
    func contract(lower: Bound.Stride? = nil, upper: Bound.Stride? = nil) -> Self {
        return (lower.map { lowerBound.advanced(by: $0)} ?? lowerBound)
            ..<
            (upper.map { upperBound.advanced(by: -1 * $0)} ?? upperBound)
    }
}
