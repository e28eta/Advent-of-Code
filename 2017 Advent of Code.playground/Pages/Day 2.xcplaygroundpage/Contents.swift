//: [Previous](@previous)
import Foundation
/*:
 # Day 2: Corruption Checksum

 As you walk through the door, a glowing humanoid shape yells in your direction. "You there! Your state appears to be idle. Come help us repair the corruption in this spreadsheet - if we take another millisecond, we'll have to display an hourglass cursor!"

 The spreadsheet consists of rows of apparently-random numbers. To make sure the recovery process is on the right track, they need you to calculate the spreadsheet's **checksum**. For each row, determine the difference between the largest value and the smallest value; the checksum is the sum of all of these differences.

 For example, given the following spreadsheet:

 ```
 5 1 9 5
 7 5 3
 2 4 6 8
 ```

 - The first row's largest and smallest values are `9` and `1`, and their difference is `8`.
 - The second row's largest and smallest values are `7` and `3`, and their difference is `4`.
 - The third row's difference is `6`.

 In this example, the spreadsheet's checksum would be `8 + 4 + 6 = 18`.

 **What is the checksum** for the spreadsheet in your puzzle input?

 */

let testData = [
    ([5, 1, 9, 5], 8),
    ([7, 5, 3], 4),
    ([2, 4, 6, 8], 6),
]
let testSpreadsheet = [(testData.map { $0.0 }, 18)]

func parse(_ string: String) -> [[Int]] {
    return string.components(separatedBy: "\n").map {
        $0.components(separatedBy: .whitespaces).flatMap { Int($0) }
    }
}

func rowDifference(_ values: [Int]) -> Int {
    guard let max = values.max(), let min = values.min() else { return 0 }
    return max - min
}

func differenceChecksum(_ spreadsheet: [[Int]]) -> Int {
    return spreadsheet.reduce(0) { sum, row in sum + rowDifference(row) }
}

verify(testData, rowDifference)
verify(testSpreadsheet, differenceChecksum)

let input = parse(try readResourceFile("input.txt"))
assertEqual(differenceChecksum(input), 45972)

/*:
 # Part Two

 "Great work; looks like we're on the right track after all. Here's a _star_ for your effort." However, the program seems a little worried. Can programs *be* worried?

 "Based on what we're seeing, it looks like all the User wanted is some information about the **evenly divisible values** in the spreadsheet. Unfortunately, none of us are equipped for that kind of calculation - most of us specialize in bitwise operations."

 It sounds like the goal is to find the only two numbers in each row where one evenly divides the other - that is, where the result of the division operation is a whole number. They would like you to find those numbers on each line, divide them, and add up each line's result.

 For example, given the following spreadsheet:

 ```
 5 9 2 8
 9 4 7 3
 3 8 6 5
 ```

 - In the first row, the only two numbers that evenly divide are `8` and `2`; the result of this division is `4`.
 - In the second row, the two numbers are `9` and `3`; the result is `3`.
 - In the third row, the result is `2`.

 In this example, the sum of the results would be `4 + 3 + 2 = 9`.

 What is the **sum of each row's result** in your puzzle input?
 */

let testData2 = [
    ([5, 9, 2, 8], 4),
    ([9, 4, 7, 3], 3),
    ([3, 8, 6, 5], 2),
]
let testSpreadsheet2 = [(testData2.map { $0.0 }, 9)]

func evenlyDivisible(_ values: [Int]) -> Int {
    return values.combinations(takenBy: 2)
        .flatMap { vals -> (Int, Int)? in
            if let max = vals.max(), let min = vals.min() {
                return (max, min)
            } else { return nil }
        }
        .filter { ($0.0 % $0.1) == 0 }
        .map { $0.0 / $0.1 }
        .first ?? 0
}

func divisibleChecksum(_ spreadsheet: [[Int]]) -> Int {
    return spreadsheet.reduce(0) { sum, row in sum + evenlyDivisible(row) }
}

verify(testData2, evenlyDivisible)
verify(testSpreadsheet2, divisibleChecksum)

assertEqual(divisibleChecksum(input), 326)


//: [Next](@next)
