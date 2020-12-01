//: [Previous](@previous)

import Foundation

/**
 --- Day 1: Report Repair ---

 After saving Christmas five years in a row, you've decided to take a vacation at a nice resort on a tropical island. Surely, Christmas will go on without you.

 The tropical island has its own currency and is entirely cash-only. The gold coins used there have a little picture of a starfish; the locals just call them stars. None of the currency exchanges seem to have heard of them, but somehow, you'll need to find fifty of these coins by the time you arrive so you can pay the deposit on your room.

 To save your vacation, you need to get all fifty stars by December 25th.

 Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

 Before you leave, the Elves in accounting just need you to fix your expense report (your puzzle input); apparently, something isn't quite adding up.

 Specifically, they need you to find the two entries that sum to 2020 and then multiply those two numbers together.

 For example, suppose your expense report contained the following:

 1721
 979
 366
 299
 675
 1456
 In this list, the two entries that sum to 2020 are 1721 and 299. Multiplying them together produces 1721 * 299 = 514579, so the correct answer is 514579.

 Of course, your expense report is much larger. Find the two entries that sum to 2020; what do you get if you multiply them together?
 */

let input = try readResourceFile("input.txt").lines().compactMap(Int.init)

// I think these are constraints
assert(input.count > 0, "there is some input")
assert(input.first! >= 0, "Should be non-negative")
assert(input.last! <= 2020, "Can't be more than limit")

func findMatch(_ ints: [Int], value: Int = 2020) -> (Int, Int)? {
    let sortedInput = ints.sorted()

    for first in sortedInput {
        for last in sortedInput.reversed() {
            if (last < first) {
                return nil
            }

            let sum = first + last
            if (sum == value) {
                return (first, last)
            } else if (sum > value) {
                // try next smaller int for `last`
                continue
            } else {
                // try next larger int for `first`
                break
            }
        }
    }

    return nil
}



verify([
    ([1721, 979, 366, 299, 675, 1456], 514579),
    (input, 32064), // solution to part 1
]) { (ints) -> Int in
    guard let (first, last) = findMatch(ints) else {
        fatalError("Did not find any matching pairs that summed to 2020")
    }
    return first * last
}

//: [Next](@next)
