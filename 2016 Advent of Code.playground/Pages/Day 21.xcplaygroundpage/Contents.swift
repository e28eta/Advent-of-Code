//: [Previous](@previous)

/*:
 # Day 21: Scrambled Letters and Hash

 The computer system you're breaking into uses a weird scrambling function to store its passwords. It shouldn't be much trouble to create your own scrambled password so you can add it to the system; you just have to implement the scrambler.

 The scrambling function is a series of operations (the exact list is provided in your puzzle input). Starting with the password to be scrambled, apply each operation in succession to the string. The individual operations behave as follows:

 * `swap position X with position Y` means that the letters at indexes `X` and `Y` (counting from `0`) should be **swapped.**
 * `swap letter X with letter Y` means that the letters `X` and `Y` should be **swapped** (regardless of where they appear in the string).
 * `rotate left/right X steps` means that the whole string should be **rotated**; for example, one right rotation would turn `abcd` into `dabc`.
 * `rotate based on position of letter X` means that the whole string should be **rotated to the right** based on the **index** of letter `X` (counting from `0`) as determined **before** this instruction does any rotations. Once the index is determined, rotate the string to the right one time, plus a number of times equal to that index, plus one additional time if the index was at least `4`.
 * `reverse positions X through Y` means that the span of letters at indexes `X` through `Y` (including the letters at `X` and `Y`) should be **reversed in order**.
 * `move position X to position Y` means that the letter which is at index `X` should be **removed** from the string, then **inserted** such that it ends up at index `Y`.


 For example, suppose you start with `abcde` and perform the following operations:

 * `swap position 4 with position 0` swaps the first and last letters, producing the input for the next step, `ebcda`.
 * `swap letter d with letter b` swaps the positions of `d` and `b`: `edcba`.
 * `reverse positions 0 through 4` causes the entire string to be reversed, producing `abcde`.
 * `rotate left 1 step` shifts all letters left one position, causing the first letter to wrap to the end of the string: `bcdea`.
 * `move position 1 to position 4` removes the letter at position `1` (`c`), then inserts it at position `4` (the end of the string): `bdeac`.
 * `move position 3 to position 0` removes the letter at position `3` (`a`), then inserts it at position `0` (the front of the string): `abdec`.
 * `rotate based on position of letter b` finds the index of letter `b` (`1`), then rotates the string right once plus a number of times equal to that index (`2`): `ecabd`.
 * `rotate based on position of letter d` finds the index of letter `d` (`4`), then rotates the string right once, plus a number of times equal to that index, plus an additional time because the index was at least `4`, for a total of `6` right rotations: `decab`.

 After these steps, the resulting scrambled password is `decab`.

 Now, you just need to generate a new scrambled password and you can access the system. Given the list of scrambling operations in your puzzle input, **what is the result of scrambling `abcdefgh`**?
 */

import Foundation

enum Direction {
    case left, right

    init(_ string: String) {
        if string == "left" {
            self = .left
        } else if string == "right" {
            self = .right
        } else {
            fatalError("unrecognized direction \(string)")
        }
    }
}

extension Array {
    mutating func rotateLeft(_ distance: Int) {
        let distance = distance % self.count

        self = Array(self.suffix(from: distance)) + self.prefix(upTo: distance)
    }

    mutating func rotateRight(_ distance: Int) {
        let length = self.count
        let distance = distance % length

        self = Array(self.suffix(distance)) + self.prefix(length - distance)
    }
}

enum ScrambleOps {
    case swapPositions(Int, Int)
    case swapLetters(Character, Character)
    case rotateDirection(Direction, Int)
    case rotateBasedOnLetter(Character)
    case reverse(Int, Int)
    case move(Int, Int)

    init(_ string: String) {
        if string.hasPrefix("swap position ") {
            let indexes = string.replacingOccurrences(of: "swap position ", with: "").components(separatedBy: " with position ")

            self = .swapPositions(Int(indexes[0])!, Int(indexes[1])!)
        } else if string.hasPrefix("swap letter ") {
            let characters = string.replacingOccurrences(of: "swap letter ", with: "").components(separatedBy: "with letter ")

            self = .swapLetters(characters[0].characters.first!, characters[1].characters.first!)
        } else if string.hasPrefix("rotate based on") {
            self = .rotateBasedOnLetter(string.characters.last!)
        } else if string.hasPrefix("rotate ") {
            let dirAndDist = string.replacingOccurrences(of: "rotate ", with: "").replacingOccurrences(of: " steps", with: "").components(separatedBy: " ")

            self = .rotateDirection(Direction(dirAndDist[0]), Int(dirAndDist[1])!)
        } else if string.hasPrefix("reverse") {
            let indexes = string.replacingOccurrences(of: "reverse positions ", with: "").components(separatedBy: " through ")

            self = .reverse(Int(indexes[0])!, Int(indexes[1])!)
        } else if string.hasPrefix("move") {
            let indexes = string.replacingOccurrences(of: "move position ", with: "").components(separatedBy: " to position ")

            self = .move(Int(indexes[0])!, Int(indexes[1])!)
        } else {
            fatalError("Unrecognized operation \(string)")
        }
    }


    func apply(_ characters: inout [Character]) {
        switch self {
        case let .swapPositions(x, y):
            guard x != y else { return }

            swap(&characters[x], &characters[y])
        case let .rotateDirection(dir, distance):
            if dir == .left {
                characters.rotateLeft(distance)
            } else if dir == .right {
                characters.rotateRight(distance)
            }
        case let .reverse(x, y):
            for (idx, char) in zip(x...y, characters[x...y].reversed()) {
                characters[idx] = char
            }
        case let .move(x, y):
            let char = characters.remove(at: x)
            characters.insert(char, at: y)
        case let .swapLetters(x, y):
            guard x != y else { return }

            guard let xIndex = characters.index(of: x) else { fatalError("missing character \(x)") }
            guard let yIndex = characters.index(of: y) else { fatalError("missing character \(y)") }

            swap(&characters[xIndex], &characters[yIndex])
        case let .rotateBasedOnLetter(char):
            guard let idx = characters.index(of: char) else { fatalError("missing character \(char)") }

            characters.rotateRight(rotateAmount(for: idx) % characters.count)
        }
    }

    func revert(_ characters: inout [Character]) {
        switch self {
        case let .swapPositions(x, y):
            guard x != y else { return }

            swap(&characters[x], &characters[y])
        case let .rotateDirection(dir, distance):
            if dir == .left {
                characters.rotateRight(distance)
            } else if dir == .right {
                characters.rotateLeft(distance)
            }
        case let .reverse(x, y):
            for (idx, char) in zip(x...y, characters[x...y].reversed()) {
                characters[idx] = char
            }
        case let .move(x, y):
            let char = characters.remove(at: y)
            characters.insert(char, at: x)
        case let .swapLetters(x, y):
            guard x != y else { return }

            guard let xIndex = characters.index(of: x) else { fatalError("missing character \(x)") }
            guard let yIndex = characters.index(of: y) else { fatalError("missing character \(y)") }

            swap(&characters[xIndex], &characters[yIndex])
        case let .rotateBasedOnLetter(char):
            guard let idx = characters.index(of: char) else { fatalError("missing character \(char)") }

            guard let destinationIndex = indexBeforeRotation(for: idx, length: characters.count) else {
                fatalError("could not determine reverse rotation amount for \(characters), \(char), \(idx)")
            }
            let rotateAmount = (characters.count + destinationIndex) - idx
            characters.rotateRight(rotateAmount)
        }
    }

    func rotateAmount(for characterIndex: Int) -> Int {
        return characterIndex + (characterIndex >= 4 ? 2 : 1)
    }

    func indexBeforeRotation(for characterIndex: Int, length: Int) -> Int? {
        // This only works if rotateAmount is relatively prime for length of characters
        return (0..<length).first(where: { characterIndex == (($0 + rotateAmount(for: $0)) % length) })
    }
}

func scramble(_ password: String, operations: [ScrambleOps]) -> String {
    var characters = Array(password.characters)

    for operation in operations {
        operation.apply(&characters)
    }

    return String(characters)
}

let example = "abcde"
let exampleOperations = "swap position 4 with position 0\nswap letter d with letter b\nreverse positions 0 through 4\nrotate left 1 step\nmove position 1 to position 4\nmove position 3 to position 0\nrotate based on position of letter b\nrotate based on position of letter d".components(separatedBy: .newlines).map { ScrambleOps($0) }

assert(scramble(example, operations: exampleOperations) == "decab")


let password = "abcdefgh"
let operations = try readResourceFile("input.txt").components(separatedBy: .newlines).map { ScrambleOps($0) }

let part1 = scramble(password, operations: operations)
assert(part1 == "bdfhgeca")

/*:
 # Part Two

 You scrambled the password correctly, but you discover that you [can't actually modify](https://en.wikipedia.org/wiki/File_system_permissions) the [password file](https://en.wikipedia.org/wiki/Passwd) on the system. You'll need to un-scramble one of the existing passwords by reversing the scrambling process.

 What is the un-scrambled version of the scrambled password `fbgdceah`?
 */

func unscramble(_ password: String, operations: [ScrambleOps]) -> String {
    var characters = Array(password.characters)

    for operation in operations.reversed() {
        operation.revert(&characters)
    }

    return String(characters)
}

let part2 = unscramble("fbgdceah", operations: operations)
assert(part2 == "gdfcabeh")

//: [Next](@next)
