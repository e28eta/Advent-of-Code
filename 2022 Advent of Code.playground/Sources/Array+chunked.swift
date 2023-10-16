import Foundation

public extension Array {
    /**
     split array into slices with a given number of elements each, last slice probably won't be full
     */
    func sliced(into size: Int) -> [ArraySlice<Element>] {
        return stride(from: startIndex, to: endIndex, by: size).map { idx in
            self[idx ..< Swift.min(idx + size, endIndex)]
        }
    }
}
