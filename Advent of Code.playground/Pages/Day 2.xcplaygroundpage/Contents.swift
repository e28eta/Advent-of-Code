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

protocol KeyPad: CustomStringConvertible {
    func moving(_ direction: Direction) -> Self
}

enum KeyPadImagined: Int, KeyPad {
    case One = 1, Two, Three
    case Four, Five, Six
    case Seven, Eight, Nine

    func moving(_ direction: Direction) -> KeyPadImagined {
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

    var description: String {
        return self.rawValue.description
    }
}

func bathroomCode(_ lines: [String], initial: KeyPad) -> String {
    return lines.reduce(("", initial)) {
        let (code, currentNumber) = $0
        let directions = Direction.parse($1)

        let nextNumber = directions.reduce(currentNumber) { $0.moving($1) }
        return (code + nextNumber.description, nextNumber)
    }.0
}

let example = ["ULL", "RRDDD", "LURDL", "UUUUD"]
assert(bathroomCode(example, initial: KeyPadImagined.Five) == "1985")


let input = try readResourceFile("input.txt")
let instructionLines = input.components(separatedBy: "\n")

let part1Answer = bathroomCode(instructionLines, initial: KeyPadImagined.Five)

assert(part1Answer == "76792")

/*:
 # Part Two

 You finally arrive at the bathroom (it's a several minute walk from the lobby so visitors can behold the many fancy conference rooms and water coolers on this floor) and go to punch in the code. Much to your bladder's dismay, the keypad is not at all like you imagined it. Instead, you are confronted with the result of hundreds of man-hours of bathroom-keypad-design meetings:

 ````
     1
   2 3 4
 5 6 7 8 9
   A B C
     D
 ````

 You still start at "5" and stop when you're at an edge, but given the same instructions as above, the outcome is very different:

 You start at "5" and don't move at all (up and left are both edges), ending at `5`.
 Continuing from "5", you move right twice and down three times (through "6", "7", "B", "D", "D"), ending at `D`.
 Then, from "D", you move five more times (through "D", "B", "C", "C", "B"), ending at `B`.
 Finally, after five more moves, you end at `3`.
 So, given the actual keypad layout, the code would be `5DB3`.

 Using the same instructions in your puzzle input, what is the correct **bathroom code**?
 */


enum KeyPadActual: String, KeyPad {
    case One = "1"
    case Two = "2", Three = "3", Four = "4"
    case Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9"
    case A = "A", B = "B", C = "C"
    case D = "D"

    func moving(_ direction: Direction) -> KeyPadActual {
        switch (self, direction) {
        case (.One, .Up), (.One, .Left), (.One, .Right), (.Three, .Up): return .One
        case (.Two, .Left), (.Two, .Up), (.Three, .Left), (.Six, .Up): return .Two
        case (.One, .Down), (.Two, .Right), (.Four, .Left), (.Seven, .Up): return .Three
        case (.Three, .Right), (.Four, .Up), (.Four, .Right), (.Eight, .Up): return .Four
        case (.Five, .Up), (.Five, .Left), (.Five, .Down), (.Six, .Left): return .Five
        case (.Two, .Down), (.Five, .Right), (.Seven, .Left), (.A, .Up): return .Six
        case (.Three, .Down), (.Six, .Right), (.Eight, .Left), (.B, .Up): return .Seven
        case (.Four, .Down), (.Seven, .Right), (.Nine, .Left), (.C, .Up): return .Eight
        case (.Eight, .Right), (.Nine, .Up), (.Nine, .Right), (.Nine, .Down): return .Nine
        case (.Six, .Down), (.A, .Left), (.A, .Down), (.B, .Left): return .A
        case (.Seven, .Down), (.A, .Right), (.C, .Left), (.D, .Up): return .B
        case (.Eight, .Down), (.B, .Right), (.C, .Right), (.C, .Down): return .C
        case (.B, .Down), (.D, .Left), (.D, .Right), (.D, .Down): return .D
        }
    }

    var description: String {
        return self.rawValue
    }
}

assert(bathroomCode(example, initial: KeyPadActual.Five) == "5DB3")

let part2Answer = bathroomCode(instructionLines, initial: KeyPadActual.Five)
assert(part2Answer == "A7AC3")

//: [Next](@next)
