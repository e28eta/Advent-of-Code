import Foundation

public extension StringProtocol {
    func splitOnce(separator: String) -> (SubSequence, SubSequence)? {
        guard let range = self.range(of: separator) else { return nil }

        let first = self.prefix(upTo: range.lowerBound)
        let second = self.suffix(from: range.upperBound)

        return (first, second)
    }

    func lines() -> [String] {
        return components(separatedBy: .newlines)
    }
}
