import Foundation

public struct RotatedRandomAccess<T: RandomAccessCollection>: RandomAccessCollection {
    public let wrapped: T
    public let offset: T.IndexDistance

    public init(wrapped: T, offset: T.IndexDistance) {
        self.wrapped = wrapped
        self.offset = offset
    }

    public subscript(position: T.Index) -> T.Element {
        let deltaToLast = wrapped.distance(from: position, to: endIndex)
        if offset < deltaToLast {
            return wrapped[wrapped.index(position, offsetBy: offset)]
        } else {
            let remainder = offset - deltaToLast
            return wrapped[wrapped.index(startIndex, offsetBy: remainder)]
        }
    }

    public var startIndex: T.Index { return wrapped.startIndex }
    public var endIndex: T.Index { return wrapped.endIndex }
    public func index(before i: T.Index) -> T.Index { return wrapped.index(before: i) }
    public func index(after i: T.Index) -> T.Index { return wrapped.index(after: i) }
}
