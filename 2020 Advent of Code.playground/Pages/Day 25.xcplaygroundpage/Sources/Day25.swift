import Foundation

struct ModuloSequence: Sequence {
    let startingValue = 1
    let subjectNumber: Int
    let modulus = 20201227

    init(_ subjectNumber: Int = 7) {
        self.subjectNumber = subjectNumber
    }

    func makeIterator() -> AnyIterator<Int> {
        var currentValue = startingValue

        return AnyIterator {
            currentValue *= subjectNumber
            currentValue %= modulus

            return currentValue
        }
    }
}

public func part1(_ publicKeys: (Int, Int)) -> Int {
    let (firstPrivateKey, matchingPublicKey) = ModuloSequence().lazy.enumerated().first { (n, v) in
        return v == publicKeys.0 || v == publicKeys.1
    }!

    let otherPublicKey = matchingPublicKey == publicKeys.0 ? publicKeys.1 : publicKeys.0
    let encryptionKey = ModuloSequence(otherPublicKey).lazy.dropFirst(firstPrivateKey).first(where: { _ in true })!

    return encryptionKey
}
