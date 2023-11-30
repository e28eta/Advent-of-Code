import Foundation

public extension Collection {
    /**
     split collection into slices with a given number of elements each, last slice probably won't be full
     */
    func sliced(into size: Int) -> some Sequence<SubSequence> {
        return sequence(state: startIndex) { idx in
            guard idx < endIndex else { return nil }
            let end = index(idx, offsetBy: size, limitedBy: endIndex) ?? endIndex
            defer { idx = end }
            return self[idx ..< end]
        }
    }
}
