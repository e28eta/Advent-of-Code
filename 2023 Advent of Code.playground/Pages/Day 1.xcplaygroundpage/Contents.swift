//: [Previous](@previous)

import Foundation

/**
 # --- Day 1: Trebuchet?! ---

 Something is wrong with global snow production, and you've been selected to take a look. The Elves have even given you a map; on it, they've used stars to mark the top fifty locations that are likely to be having problems.

 You've been doing this long enough to know that to restore snow operations, you need to check all **fifty stars** by December 25th.

 Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants **one star**. Good luck!

 You try to ask why they can't just use a [weather machine](https://adventofcode.com/2015/day/1) ("not powerful enough") and where they're even sending you ("the sky") and why your map looks mostly blank ("you sure ask a lot of questions") and hang on did you just say the sky ("of course, where do you think snow comes from") when you realize that the Elves are already loading you into a [trebuchet](https://en.wikipedia.org/wiki/Trebuchet) ("please hold still, we need to strap you in").

 As they're making the final adjustments, they discover that their calibration document (your puzzle input) has been **amended** by a very young Elf who was apparently just excited to show off her art skills. Consequently, the Elves are having trouble reading the values on the document.

 The newly-improved calibration document consists of lines of text; each line originally contained a specific **calibration value** that the Elves now need to recover. On each line, the calibration value can be found by combining the **first digit** and the **last digit** (in that order) to form a single **two-digit number.**

 For example:

 ```
 1abc2
 pqr3stu8vwx
 a1b2c3d4e5f
 treb7uchet
 ```

 In this example, the calibration values of these four lines are `12`, `38`, `15`, and `77`. Adding these together produces `142`.

 Consider your entire calibration document. **What is the sum of all of the calibration values?**
 */

let testInput = """
1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
"""
let input = try readResourceFile("input.txt")

func parse(_ d: some StringProtocol) -> Int? {
    switch d {
    case "one": return 1
    case "two": return 2
    case "three": return 3
    case "four": return 4
    case "five": return 5
    case "six": return 6
    case "seven": return 7
    case "eight": return 8
    case "nine": return 9
    default: return Int(d)
    }
}

func part1(_ string: String) -> Int {
    let regex = /(\d)/

    return string.lines()
        .compactMap {
            let matches = $0.matches(of: regex)

            guard let d1 = matches.first?.1,
                  let d2 = matches.last?.1,
                  let i1 = parse(d1),
                  let i2 = parse(d2) else {
                return nil
            }

            return i1 * 10 + i2
        }
        .reduce(0, +)
}

verify([
    (testInput, 142),
    (input, 56108),
], part1)

/**
 # --- Part Two ---

 Your calculation isn't quite right. It looks like some of the digits are actually **spelled out with letters:** `one`, `two`, `three`, `four`, `five`, `six`, `seven`, `eight`, and `nine` also count as valid "digits".

 Equipped with this new information, you now need to find the real first and last digit on each line. For example:

 ```
 two1nine
 eightwothree
 abcone2threexyz
 xtwone3four
 4nineeightseven2
 zoneight234
 7pqrstsixteen
 ```

 In this example, the calibration values are `29`, `83`, `13`, `24`, `42`, `14`, and `76`. Adding these together produces `281`.

  **What is the sum of all of the calibration values?**
 */

let testInput2 = """
two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
"""

func part2(_ string: String) -> Int {
    let regex = /(\d|one|two|three|four|five|six|seven|eight|nine)/

    return string.lines()
        .compactMap { line in
            // idk how to get all overlapping matches, and
            // turns out that was my problem.
            // Instead, start at end of line & step toward
            // the front until I find a match for the regex
            // Could have reversed() string / regex literal to
            // save some runtime, but more typing...
            let lastIndex = line.indices
                .reversed()
                .first { idx in
                    (try? regex.firstMatch(in: line[idx...])) != nil
                }

            guard let lastIndex,
                let d1 = line.firstMatch(of: regex)?.1,
                  let d2 = line[lastIndex...].firstMatch(of: regex)?.1,
                  let i1 = parse(d1),
                  let i2 = parse(d2) else {
                return nil
            }

            return i1 * 10 + i2
        }
        .reduce(0, +)
}


verify([
    (testInput2, 281),
    ("8rstj9onetwonem", 81), // had to compare correct solution with mine to find this test case
    (input, 55652)
], part2)

//: [Next](@next)
