import Foundation

public extension StringProtocol {
    /**
     If this string contains the `separator`, returns a tuple with the substrings before & after
     the first occurrence of that separator.
     If the `separator` isn't found in the string, returns nil
     */
    func splitOnce(separator: String) -> (SubSequence, SubSequence)? {
        guard let range = self.range(of: separator) else { return nil }

        let first = self.prefix(upTo: range.lowerBound)
        let second = self.suffix(from: range.upperBound)

        return (first, second)
    }

    /**
     separates this string into an array of Strings, one for each line
     */
    func lines() -> [String] {
        return components(separatedBy: .newlines)
    }
}
