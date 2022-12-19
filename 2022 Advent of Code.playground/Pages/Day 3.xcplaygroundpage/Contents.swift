//: [Previous](@previous)

import Foundation

/**
 --- Day 3: Rucksack Reorganization ---

 One Elf has the important job of loading all of the [rucksacks](https://en.wikipedia.org/wiki/Rucksack) with supplies for the jungle journey. Unfortunately, that Elf didn't quite follow the packing instructions, and so a few items now need to be rearranged.

 Each rucksack has two large **compartments**. All items of a given type are meant to go into exactly one of the two compartments. The Elf that did the packing failed to follow this rule for exactly one item type per rucksack.

 The Elves have made a list of all of the items currently in each rucksack (your puzzle input), but they need your help finding the errors. Every item type is identified by a single lowercase or uppercase letter (that is, `a` and `A` refer to different types of items).

 The list of items for each rucksack is given as characters all on a single line. A given rucksack always has the same number of items in each of its two compartments, so the first half of the characters represent items in the first compartment, while the second half of the characters represent items in the second compartment.

 For example, suppose you have the following list of contents from six rucksacks:
 ```
 vJrwpWtwJgWrhcsFMMfFFhFp
 jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
 PmmdzqPrVvPwwTWBwg
 wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
 ttgJtRGJQctTZtZT
 CrZsJsPPZsGzwwsLwLmpwMDw
 ```

 * The first rucksack contains the items `vJrwpWtwJgWrhcsFMMfFFhFp`, which means its first compartment contains the items `vJrwpWtwJgWr`, while the second compartment contains the items `hcsFMMfFFhFp`. The only item type that appears in both compartments is lowercase `p`.
 * The second rucksack's compartments contain `jqHRNqRjqzjGDLGL` and `rsFMfFZSrLrFZsSL`. The only item type that appears in both compartments is uppercase `L`.
 * The third rucksack's compartments contain `PmmdzqPrV` and `vPwwTWBwg`; the only common item type is uppercase `P`.
 * The fourth rucksack's compartments only share item type `v`.
 * The fifth rucksack's compartments only share item type `t`.
 * The sixth rucksack's compartments only share item type `s`.

 To help prioritize item rearrangement, every item type can be converted to a priority:

 - Lowercase item types `a` through `z` have priorities `1` through `26`.
 - Uppercase item types `A` through `Z` have priorities `27` through `52`.

 In the above example, the priority of the item type that appears in both compartments of each rucksack is 16 (`p`), 38 (`L`), 42 (`P`), 22 (`v`), 20 (`t`), and 19 (`s`); the sum of these is `157`.

 Find the item type that appears in both compartments of each rucksack. **What is the sum of the priorities of those item types?**
 */

let capitalA = UInt8(ascii: "A")
let lowercaseA = UInt8(ascii: "a")

extension Character {
    var priority: UInt8 {
        guard self.isASCII else { return 0 }

        if self.isLowercase {
            return 1 + self.asciiValue! - lowercaseA
        } else {
            return 27 + self.asciiValue! - capitalA
        }
    }
}

struct Rucksack {
    let left: Set<Character>
    let right: Set<Character>

    init(_ contents: String) {
        let midpoint = contents.count / 2
        let midpointIndex = contents.index(contents.startIndex, offsetBy: midpoint)

        left = Set(contents[..<midpointIndex])
        right = Set(contents[midpointIndex...])
    }

    var duplicateItemPriority: UInt8 {
        return left.intersection(right).reduce(0) { $0 + $1.priority }
    }
}

let testInput = """
vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw
"""

let input = try readResourceFile("input.txt")

verify([
    (testInput, 157),
    (input, 7793),
], { input in
    input.lines().map(Rucksack.init).reduce(0) { $0 + Int($1.duplicateItemPriority) }
})


//: [Next](@next)
