//: [Previous](@previous)

/*:
 # Day 20: Firewall Rules

 You'd like to set up a small hidden computer here so you can use it to get back into the network later. However, the corporate firewall only allows communication with certain external [IP addresses](https://en.wikipedia.org/wiki/IPv4#Addressing).

 You've retrieved the list of blocked IPs from the firewall, but the list seems to be messy and poorly maintained, and it's not clear which IPs are allowed. Also, rather than being written in [dot-decimal](https://en.wikipedia.org/wiki/Dot-decimal_notation) notation, they are written as plain [32-bit integers](https://en.wikipedia.org/wiki/32-bit), which can have any value from `0` through `4294967295`, inclusive.

 For example, suppose only the values `0` through `9` were valid, and that you retrieved the following blacklist:

 ````
 5-8
 0-2
 4-7
 ````

 The blacklist specifies ranges of IPs (inclusive of both the start and end value) that are **not** allowed. Then, the only IPs that this firewall allows are `3` and `9`, since those are the only numbers not in any range.

 Given the list of blocked IPs you retrieved from the firewall (your puzzle input), **what is the lowest-valued IP** that is not blocked?
 */

import Foundation

let exampleInput = "5-8\n0-2\n4-7"

func parse(_ string: String) -> [CountableClosedRange<Int>] {
    return string.components(separatedBy: .newlines).map {
        $0.components(separatedBy: "-")
        }.map {
            let asInts = $0.flatMap {
                Int($0, radix: 10)
            }

            return (asInts[0])...(asInts[1])
    }
}

let example = parse(exampleInput).sorted { $0.0.lowerBound < $0.1.lowerBound }
print(example)

func firstExcluded(_ ranges: [CountableClosedRange<Int>], in fullRange: CountableClosedRange<Int>) -> Int? {

    var numberToCheck = fullRange.lowerBound

    for range in ranges {
        if numberToCheck < range.lowerBound {
            return numberToCheck
        } else if range.contains(numberToCheck) {
            numberToCheck = range.upperBound + 1
        }
    }

    if fullRange.contains(numberToCheck) {
        return numberToCheck
    } else {
        print("I believe the fullRange is fully covered by all the ranges")
        return nil
    }
}

for (range, answer): (CountableClosedRange<Int>, Int?) in [(0...9, 3), (-1...9, -1), (4...9, 9), (4...8, .none)] {
    assert(answer == firstExcluded(example, in: range))
}


let input = try readResourceFile("input.txt")
let parsed = parse(input).sorted { $0.0.lowerBound < $0.1.lowerBound }
parsed

let thirtyTwoBitInts = (0...4294967295)
let part1Answer = firstExcluded(parsed, in: thirtyTwoBitInts)
assert(part1Answer == 23923783)

/*:
 # Part Two

 **How many IPs** are allowed by the blacklist?
 */

func totalExcluded(from ranges: [CountableClosedRange<Int>], in fullRange: CountableClosedRange<Int>) -> Int {
    var numberToCheck = fullRange.lowerBound
    var count = 0

    for range in ranges {
        if numberToCheck < range.lowerBound {
            count += (range.lowerBound - numberToCheck)

            numberToCheck = range.upperBound + 1
        } else if range.contains(numberToCheck) {
            numberToCheck = range.upperBound + 1
        }
    }

    if fullRange.contains(numberToCheck) {
        count += (fullRange.upperBound + 1 - numberToCheck)
    }

    return count
}

for (range, answer): (CountableClosedRange<Int>, Int) in [(0...9, 2), (0...10, 3), (-1...9, 3), (4...9, 1), (4...8, 0)] {
    assert(answer == totalExcluded(from: example, in: range))
}

let part2Answer = totalExcluded(from: parsed, in: thirtyTwoBitInts)
assert(part2Answer == 125)

//: [Next](@next)
