//: [Previous](@previous)
/*:
 # Day 4: Security Through Obscurity

 Finally, you come across an information kiosk with a list of rooms. Of course, the list is encrypted and full of decoy data, but the instructions to decode the list are barely hidden nearby. Better remove the decoy data first.

 Each room consists of an encrypted name (lowercase letters separated by dashes) followed by a dash, a sector ID, and a checksum in square brackets.

 A room is real (not a decoy) if the checksum is the five most common letters in the encrypted name, in order, with ties broken by alphabetization. For example:

 `aaaaa-bbb-z-y-x-123[abxyz]` is a real room because the most common letters are `a` (5), `b` (3), and then a tie between `x`, `y`, and `z`, which are listed alphabetically.
 `a-b-c-d-e-f-g-h-987[abcde]` is a real room because although the letters are all tied (1 of each), the first five are listed alphabetically.
 `not-a-real-room-404[oarel]` is a real room.
 `totally-real-room-200[decoy]` is not.
 Of the real rooms from the list above, the sum of their sector IDs is `1514`.

 What is the **sum of the sector IDs of the real rooms?**
 */
import Foundation

struct Room {
    let encryptedName: [String]
    let sectorID: Int
    let purportedChecksum: String

    var isReal: Bool {
        return purportedChecksum == self.calculateChecksum()
    }

    init?(_ string: String) {
        var elements = string.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "-")

        guard let idAndChecksum = elements.popLast() else {
            return nil
        }
        encryptedName = elements

        elements = idAndChecksum.components(separatedBy: "[")
        guard let idString = elements.first, let sectorID = Int(idString, radix: 10) else {
            return nil
        }
        self.sectorID = sectorID

        guard let checksum = elements.last?.replacingOccurrences(of: "]", with: "") else {
            return nil
        }
        self.purportedChecksum = checksum
    }

    typealias CharacterFrequency = [Character: Int]


    private func buildFrequencyTable(_ string: String) -> CharacterFrequency {
        var frequencies: CharacterFrequency = [:]

        for char in string.characters {
            let currentCount = frequencies[char] ?? 0
            frequencies[char] = currentCount + 1
        }

        return frequencies
    }

    private let descendingValueAscendingKeys = { (left: CharacterFrequency.Element, right: CharacterFrequency.Element) -> Bool in
        if left.value != right.value {
            // sorted descending by value (the frequency of the character)
            return left.value > right.value
        } else {
            // ties for count, sorted ascending by character (aka: alphabetical order)
            return left.key < right.key
        }
    }

    func calculateChecksum() -> String {
        return buildFrequencyTable(self.encryptedName.joined())
            .sorted(by: descendingValueAscendingKeys)
            .lazy
            .map { String($0.key) }
            .prefix(5)
            .joined()
    }

    static func realRoomSectorIdSum(_ rooms: [Room]) -> Int {
        return rooms.filter { $0.isReal }.reduce(0) { $0 + $1.sectorID }
    }
}



let testRooms = [Room("aaaaa-bbb-z-y-x-123[abxyz]"),
                 Room("a-b-c-d-e-f-g-h-987[abcde]"),
                 Room("not-a-real-room-404[oarel]"),
                 Room("totally-real-room-200[decoy]")].flatMap { $0 }


assert(testRooms.map { $0.isReal } == [true, true, true, false])
assert(Room.realRoomSectorIdSum(testRooms) == 1514)


let input = try readResourceFile("input.txt").trimmingCharacters(in: .whitespacesAndNewlines)
let rooms = input.components(separatedBy: .newlines).flatMap { Room($0) }
let realRooms = rooms.filter { $0.isReal }
let part1Answer = realRooms.reduce(0) { $0 + $1.sectorID }

assert(part1Answer == 158835)

/*:
 # Part Two

 With all the decoy data out of the way, it's time to decrypt this list and get moving.

 The room names are encrypted by a state-of-the-art [shift cipher](https://en.wikipedia.org/wiki/Caesar_cipher), which is nearly unbreakable without the right software. However, the information kiosk designers at Easter Bunny HQ were not expecting to deal with a master cryptographer like yourself.

 To decrypt a room name, rotate each letter forward through the alphabet a number of times equal to the room's sector ID. `A` becomes `B`, `B` becomes `C`, `Z` becomes `A`, and so on. Dashes become spaces.

 For example, the real name for qzmt-zixmtkozy-ivhz-343 is very encrypted name.

 **What is the sector ID** of the room where North Pole objects are stored?
 */

extension Room {
    func decryptedName() -> String {
        return self.encryptedName.map { word -> String in
            word.unicodeScalars.map { char -> String in
                let charValue = Int(char.value) - 97
                let decryptedValue = (charValue + sectorID) % 26 + 97
                return String(UnicodeScalar(decryptedValue)!)
                }.joined()
            }.joined(separator: " ")
    }
}

guard let encryptedRoom = Room("qzmt-zixmtkozy-ivhz-343[abcde]") else { fatalError() }
assert(encryptedRoom.decryptedName() == "very encrypted name")

for room in realRooms {
    print(room.sectorID, ": ", room.decryptedName(), separator: "")
}

let part2Answer = realRooms.first { $0.decryptedName() == "northpole object storage" }?.sectorID
assert(part2Answer == 993)



//: [Next](@next)
