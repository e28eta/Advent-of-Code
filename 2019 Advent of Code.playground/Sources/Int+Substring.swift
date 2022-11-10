import Foundation

public extension Int {
    // makes split(separator: ",").compactMap(Int.init) work. Not sure why this
    // isn't built-in, or why the built-in one doesn't work for this type of usage
    init?<S: StringProtocol>(_ s: S) {
        self.init(s, radix: 10)
    }
}
