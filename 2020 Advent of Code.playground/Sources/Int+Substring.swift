import Foundation

public extension Int {
    // makes split(separator: ",").compactMap(Int.init) work
    init?(_ s: Substring) {
        self.init(String(s))
    }
}
