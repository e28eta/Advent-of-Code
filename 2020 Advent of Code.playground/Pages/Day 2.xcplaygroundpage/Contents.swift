//: [Previous](@previous)

import Foundation

/**
 --- Day 2: Password Philosophy ---

 Your flight departs in a few days from the coastal airport; the easiest way down to the coast from here is via toboggan.

 The shopkeeper at the North Pole Toboggan Rental Shop is having a bad day. "Something's wrong with our computers; we can't log in!" You ask if you can take a look.

 Their password database seems to be a little corrupted: some of the passwords wouldn't have been allowed by the Official Toboggan Corporate Policy that was in effect when they were chosen.

 To try to debug the problem, they have created a list (your puzzle input) of passwords (according to the corrupted database) and the corporate policy when that password was set.

 For example, suppose you have the following list:

 1-3 a: abcde
 1-3 b: cdefg
 2-9 c: ccccccccc
 Each line gives the password policy and then the password. The password policy indicates the lowest and highest number of times a given letter must appear for the password to be valid. For example, 1-3 a means that the password must contain a at least 1 time and at most 3 times.

 In the above example, 2 passwords are valid. The middle password, cdefg, is not; it contains no instances of b, but needs at least 1. The first and third passwords are valid: they contain one a or nine c, both within the limits of their respective policies.

 How many passwords are valid according to their policies?
 */

struct PasswordDbEntry {
    let range: ClosedRange<Int>
    let requiredCharacter: Character
    let password: String

    init?(line: String) {
        let lineComponents = line.split(separator: " ")

        guard lineComponents.count == 3,
            let range = lineComponents.first?.split(separator: "-").compactMap({ Int($0) }),
            range.count == 2,
              let char = lineComponents[1].first else {
            print("Failed to parse DB entry \(line)")
            return nil
        }

        self.range = (range[0] ... range[1])
        self.requiredCharacter = char
        self.password = String(lineComponents[2])
    }

    func isValid() -> Bool {
        return range.contains(password.filter({ $0 == requiredCharacter }).count)
    }
}

let input = try readResourceFile("input.txt").lines()
var parsed = input.compactMap(PasswordDbEntry.init)

verify([
    ("1-3 a: abcde", true),
    ("1-3 b: cdefg", false),
    ("2-9 c: ccccccccc", true),
]) {
    PasswordDbEntry(line: $0)!.isValid()
}

let validPasswords = parsed.filter { $0.isValid() }
assert(validPasswords.count == 645)


//: [Next](@next)
