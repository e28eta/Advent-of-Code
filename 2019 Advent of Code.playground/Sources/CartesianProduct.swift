import Foundation

public struct CartesianProduct<T: Sequence, U: Collection> {
    private var outer: T
    private var inner: U

    public init(_ outer: T, _ inner: U) {
        self.outer = outer
        self.inner = inner
    }
}

extension CartesianProduct: Sequence {
    public func makeIterator() -> AnyIterator<(T.Element, U.Element)> {
        var outerIterator = outer.makeIterator()
        var outerValue = outerIterator.next()

        if outerValue == nil || inner.isEmpty {
            return AnyIterator { return nil }
        }

        var innerIterator = inner.makeIterator()
        var innerValue: U.Element? = innerIterator.next()

        return AnyIterator { () -> (T.Element, U.Element)? in
            guard outerValue != nil else { return nil }

            defer {
                innerValue = innerIterator.next()

                if innerValue == nil {
                    outerValue = outerIterator.next()
                    innerIterator = inner.makeIterator()
                    innerValue = innerIterator.next()
                }
            }

            return (outerValue!, innerValue!)
        }
    }
}
