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

public func solvePartTwo(_ string: String, start: Int = 0, length: Int = 8, end: Int = Int.max) -> String {
    let range = (start...end).lazy

    let hashPrefixes = range.map { (num: Int) -> String in
        let candidate = string + num.description

        return MD5().calculate(for: candidate.utf8.lazy.map {
            $0 as UInt8
        }).prefix(4).toHexString()
    }
    let filtered = hashPrefixes.filter { (hash: String) -> Bool in
        hash.hasPrefix("00000")
    }

    guard length < 16 else {
        fatalError("length must be less than 16: \(length)")
    }
    let validIndexes = ("0"..<(String(length, radix: 16)))
    var iterator = filtered.makeIterator()
    var password: [String?] = Array(repeating: nil, count: length)

    repeat {
        guard let nextHash = iterator.next() else {
            print("error, ran out of hashes")
            break
        }
        let indexAndValue = nextHash.characters.dropFirst(5).dropLast()
        guard let index = indexAndValue.first, let value = indexAndValue.last else {
            fatalError("hash wasn't long enough? \(nextHash)")
        }
        let indexString = String(index)

        guard validIndexes.contains(indexString) else {
            continue
        }

        guard let intIndex = Int(indexString, radix: 16), password[intIndex] == nil else {
            continue
        }

        password[intIndex] = String(value)
    } while password.contains { $0 == nil }


    return password.map { $0 ?? "_" }.joined()
}
