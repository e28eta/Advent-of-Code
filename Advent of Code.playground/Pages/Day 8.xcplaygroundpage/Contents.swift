//: [Previous](@previous)

/*:
 # Day 8: Two-Factor Authentication ---

 You come across a door implementing what you can only assume is an implementation of [two-factor authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication) after a long game of [requirements](https://en.wikipedia.org/wiki/Requirement) [telephone](https://en.wikipedia.org/wiki/Chinese_whispers).

 To get past the door, you first swipe a keycard (no problem; there was one on a nearby desk). Then, it displays a code on a [little screen](https://www.google.com/search?q=tiny+lcd&tbm=isch), and you type that code on a keypad. Then, presumably, the door unlocks.

 Unfortunately, the screen has been smashed. After a few minutes, you've taken everything apart and figured out how it works. Now you just have to work out what the screen **would** have displayed.

 The magnetic strip on the card you swiped encodes a series of instructions for the screen; these instructions are your puzzle input. The screen is **50 pixels wide and 6 pixels tall**, all of which start **off**, and is capable of three somewhat peculiar operations:

 `rect AxB` turns **on** all of the pixels in a rectangle at the top-left of the screen which is `A` wide and `B` tall.
 `rotate row y=A by B` shifts all of the pixels in row `A` (0 is the top row) **right** by `B` pixels. Pixels that would fall off the right end appear at the left end of the row.
 `rotate column x=A by B` shifts all of the pixels in column `A` (0 is the left column) **down** by `B` pixels. Pixels that would fall off the bottom appear at the top of the column.
 For example, here is a simple sequence on a smaller screen:

 `rect 3x2` creates a small rectangle in the top-left corner:
````
 ###....
 ###....
 .......
````
 `rotate column x=1 by 1` rotates the second column down by one pixel:
````
 #.#....
 ###....
 .#.....
````
 `rotate row y=0 by 4` rotates the top row right by four pixels:
````
 ....#.#
 ###....
 .#.....
````
 `rotate column x=1 by 1` again rotates the second column down by one pixel, causing the bottom pixel to wrap back to the top:
````
 .#..#.#
 #.#....
 .#.....
````
 As you can see, this display technology is extremely powerful, and will soon dominate the tiny-code-displaying-screen market. That's what the advertisement on the back of the display tries to convince you, anyway.

 There seems to be an intermediate check of the voltage used by the display: after you swipe your card, if the screen did work, **how many pixels should be lit**?
 */
import Foundation

enum PixelState: CustomStringConvertible {
    case Off, On

    var description: String {
        switch self {
        case .Off: return "."
        case .On: return "#"
        }
    }
}

enum Action: Equatable {
    case TurnOnRect(width: Int, height: Int)
    case RotateColumnDown(column: Int, amount: Int)
    case RotateRowRight(row: Int, amount: Int)

    init?(_ string: String) {
        if string.hasPrefix("rect ") {
            let numbers = string.replacingOccurrences(of: "rect ", with: "").components(separatedBy: "x")
            guard let width = Int(numbers[0], radix: 10), let height = Int(numbers[1], radix: 10) else { return nil }
            self = .TurnOnRect(width: width, height: height)
        } else if string.hasPrefix("rotate row y=") {
            let numbers = string.replacingOccurrences(of: "rotate row y=", with: "").components(separatedBy: " by ")
            guard let row = Int(numbers[0], radix: 10), let amount = Int(numbers[1], radix: 10) else { return nil }
            self = .RotateRowRight(row: row, amount: amount)
        } else if string.hasPrefix("rotate column x=") {
            let numbers = string.replacingOccurrences(of: "rotate column x=", with: "").components(separatedBy: " by ")
            guard let column = Int(numbers[0], radix: 10), let amount = Int(numbers[1], radix: 10) else { return nil }
            self = .RotateColumnDown(column: column, amount: amount)
        } else {
            return nil
        }
    }

    public static func ==(lhs: Action, rhs: Action) -> Bool {
        switch (lhs, rhs) {
        case let (.TurnOnRect(w1, h1), .TurnOnRect(w2, h2)):
            return w1 == w2 && h1 == h2
        case let (.RotateColumnDown(c1, a1), .RotateColumnDown(c2, a2)):
            return c1 == c2 && a1 == a2
        case let (.RotateRowRight(r1, a1), .RotateRowRight(r2, a2)):
            return r1 == r2 && a1 == a2
        default:
            return false
        }
    }
}

extension Array {
    func rotated(_ amount: Int) -> Array {
        let indexToSplitAt = self.count - amount
        let newPrefix = self.suffix(from: indexToSplitAt)
        let newSuffix = self.prefix(upTo: indexToSplitAt)

        return Array(newPrefix) + newSuffix
    }
}

struct Screen: CustomStringConvertible {
    var pixels: [[PixelState]]

    init(width: Int, height: Int) {
        pixels = Array(repeating: Array(repeating: .Off, count: width), count: height)
    }

    mutating func takeAction(_ action: Action) {
        switch action {
        case let .TurnOnRect(width, height):
            for row in (0..<height) {
                for column in (0..<width) {
                    pixels[row][column] = .On
                }
            }
        case let .RotateColumnDown(column, amount):
            let rotatedColumn = pixels.map { $0[column] }.rotated(amount)
            for row in (0..<pixels.count) {
                pixels[row][column] = rotatedColumn[row]
            }
        case let .RotateRowRight(row, amount):
            pixels[row] = pixels[row].rotated(amount)
        }
    }

    var description: String {
        return pixels.map { $0.map { $0.description }.joined() + "\n" }.joined()
    }

    var numPixelsLit: Int {
        return pixels.reduce(0) { $1.reduce($0) { $0 + ($1 == .On ? 1 : 0) } }
    }
}

var exampleActions = ["rect 3x2", "rotate column x=1 by 1", "rotate row y=0 by 4", "rotate column x=1 by 1"].flatMap { Action($0) }
var expectedActions: [Action] = [.TurnOnRect(width: 3, height: 2), .RotateColumnDown(column: 1, amount: 1), .RotateRowRight(row: 0, amount: 4), .RotateColumnDown(column: 1, amount: 1)]

assert(exampleActions == expectedActions)

var exampleScreen = Screen(width: 7, height: 3)
for action in exampleActions {
    exampleScreen.takeAction(action)
    print(exampleScreen)
}
assert(exampleScreen.numPixelsLit == 6)



let input = try readResourceFile("input.txt").components(separatedBy: .newlines)
let actions = input.flatMap { Action($0) }
assert(input.count == actions.count)
var screen = Screen(width: 50, height: 6)
for action in actions {

    screen.takeAction(action)
}

let part1Answer = screen.numPixelsLit
assert(part1Answer == 121)


/*:
 # Part Two

 You notice that the screen is only capable of displaying capital letters; in the font it uses, each letter is 5 pixels wide and 6 tall.

 After you swipe your card, what code is the screen trying to display?
 */

print(screen)
// RURUCEOEIL

//: [Next](@next)
