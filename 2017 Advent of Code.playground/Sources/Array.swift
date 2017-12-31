import Foundation

extension Array {
    public func index(wrapping index: Index) -> Index {
        return (index % count + count) % count + startIndex
    }
}
