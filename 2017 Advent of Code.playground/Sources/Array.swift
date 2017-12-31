import Foundation

extension Array {
    public func index(wrapping index: Index) -> Index {
        return (index % count + count) % count + startIndex
    }

    public func taking(chunksOf length: Int) -> AnyIterator<ArraySlice<Element>> {
        let str = stride(from: startIndex, through: endIndex, by: length)
        var seq = zip(str, str.dropFirst()).makeIterator()

        return AnyIterator<ArraySlice<Element>> { () -> ArraySlice<Element>? in
            guard let (start, end) = seq.next() else { return nil }

            return self[start ..< end]
        }
    }
}
