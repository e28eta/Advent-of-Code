//: [Previous](@previous)
/*:
 # Day 2: Bathroom Security

 You arrive at **Easter Bunny Headquarters** under cover of darkness. However, you left in such a rush that you forgot to use the bathroom! Fancy office buildings like this one usually have keypad locks on their bathrooms, so you search the front desk for the code.

 "In order to improve security," the document you find says, "bathroom codes will no longer be written down. Instead, please memorize and follow the procedure below to access the bathrooms."

 The document goes on to explain that each button to be pressed can be found by starting on the previous button and moving to adjacent buttons on the keypad: `U` moves up, `D` moves down, `L` moves left, and `R` moves right. Each line of instructions corresponds to one button, starting at the previous button (or, for the first line, **the "5" button**); press whatever button you're on at the end of each line. If a move doesn't lead to a button, ignore it.

 You can't hold it much longer, so you decide to figure out the code as you walk to the bathroom. You picture a keypad like this:
 ````
 1 2 3
 4 5 6
 7 8 9
 ````
 Suppose your instructions are:

 ````
 ULL
 RRDDD
 LURDL
 UUUUD
 ````

 You start at "5" and move up (to "2"), left (to "1"), and left (you can't, and stay on "1"), so the first button is `1`.
 Starting from the previous button ("1"), you move right twice (to "3") and then down three times (stopping at "9" after two moves and ignoring the third), ending up with `9`.
 Continuing from "9", you move left, up, right, down, and left, ending with `8`.
 Finally, you move up four times (stopping at "2"), then down once, ending with `5`.
 So, in this example, the bathroom code is `1985`.

 Your puzzle input is the instructions from the document you found at the front desk. What is the **bathroom code**?
 */
import Foundation

enum Direction: Character {
    case Up = "U", Down = "D", Left = "L", Right = "R"

    static func parse(_ string: String) -> [Direction] {
        return string.characters.map { Direction(rawValue: $0)! }
    }
}

enum KeyPadNumber: Int {
    case One = 1, Two, Three
    case Four, Five, Six
    case Seven, Eight, Nine

    func moving(_ direction: Direction) -> KeyPadNumber {
        switch (self, direction) {
        case (.One, .Up), (.One, .Left), (.Two, .Left), (.Four, .Up): return .One
        case (.One, .Right), (.Two, .Up), (.Three, .Left), (.Five, .Up): return .Two
        case (.Two, .Right), (.Three, .Up), (.Three, .Right), (.Six, .Up): return .Three
        case (.One, .Down), (.Four, .Left), (.Five, .Left), (.Seven, .Up): return .Four
        case (.Two, .Down), (.Four, .Right), (.Six, .Left), (.Eight, .Up): return .Five
        case (.Three, .Down), (.Five, .Right), (.Six, .Right), (.Nine, .Up): return .Six
        case (.Four, .Down), (.Seven, .Left), (.Seven, .Down), (.Eight, .Left): return .Seven
        case (.Five, .Down), (.Seven, .Right), (.Eight, .Down), (.Nine, .Left): return .Eight
        case (.Six, .Down), (.Eight, .Right), (.Nine, .Right), (.Nine, .Down): return .Nine
        }
    }
}

func bathroomCode(_ lines: [String]) -> String {
    return lines.reduce(("", KeyPadNumber.Five)) {
        let (code, currentNumber) = $0
        let directions = Direction.parse($1)

        let nextNumber = directions.reduce(currentNumber) { $0.moving($1) }
        return (code + nextNumber.rawValue.description, nextNumber)
    }.0
}

let example = ["ULL", "RRDDD", "LURDL", "UUUUD"]
assert(bathroomCode(example) == "1985")


let input = try readResourceFile("input.txt").trimmingCharacters(in: .whitespacesAndNewlines)
let instructionLines = input.components(separatedBy: "\n")

let part1Answer = bathroomCode(instructionLines)

assert(part1Answer == "76792")

//: [Next](@next)
