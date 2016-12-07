import Foundation

public func solvePartOne(_ string: String, start: Int = 0, length: Int = 8, end: Int = Int.max) -> String {
    let range = (start...end).lazy

    let hashPrefixes = range.map { (num: Int) -> String in
        let candidate = string + num.description

        return MD5().calculate(for: candidate.utf8.lazy.map {
            $0 as UInt8
        }).prefix(3).toHexString()
    }
    let filtered = hashPrefixes.filter { (hash: String) -> Bool in
        hash.hasPrefix("00000")
    }
    let firstN = filtered.prefix(length)

    let result = firstN.map { (hash: String) -> String in
        String(hash.characters.last!)
    }

    return result.joined()
}

