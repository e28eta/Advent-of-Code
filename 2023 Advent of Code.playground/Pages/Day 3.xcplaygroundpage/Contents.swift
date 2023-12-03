//: [Previous](@previous)

import Foundation

/**
 # --- Day 3: Gear Ratios ---

 You and the Elf eventually reach a [gondola lift](https://en.wikipedia.org/wiki/Gondola_lift) station; he says the gondola lift will take you up to the **water source**, but this is as far as he can bring you. You go inside.

 It doesn't take long to find the gondolas, but there seems to be a problem: they're not moving.

 "Aaah!"

 You turn around to see a slightly-greasy Elf with a wrench and a look of surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working right now; it'll still be a while before I can fix it." You offer to help.

 The engineer explains that an engine part seems to be missing from the engine, but nobody can figure out which one. If you can **add up all the part numbers** in the engine schematic, it should be easy to work out which part is missing.

 The engine schematic (your puzzle input) consists of a visual representation of the engine. There are lots of numbers and symbols you don't really understand, but apparently **any number adjacent to a symbol,** even diagonally, is a "part number" and should be included in your sum. (Periods (`.`) do not count as a symbol.)

 Here is an example engine schematic:

 ```
 467..114..
 ...*......
 ..35..633.
 ......#...
 617*......
 .....+.58.
 ..592.....
 ......755.
 ...$.*....
 .664.598..
 ```

 In this schematic, two numbers are **not** part numbers because they are not adjacent to a symbol: `114` (top right) and `58` (middle right). Every other number is adjacent to a symbol and so **is** a part number; their sum is `4361`.

 Of course, the actual engine schematic is much larger. **What is the sum of all of the part numbers in the engine schematic?**
 */

let testInput = """
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
"""
let input = try readResourceFile("input.txt")

extension Grid where Element == Character {
    public func numbersAndNeighboringSymbols() -> some Sequence<(Int, Set<GridIndex>)> {
        return (0 ..< height).flatMap { rowIdx in
            var result: [(Int, Set<GridIndex>)] = []
            var partialNumber = 0
            var adjacentSymbols = Set<Index>()

            // go through width to always close number at end of line
            for colIdx in (0 ... width) {
                let c = self[rowIdx, colIdx]

                if let val = c?.wholeNumberValue {
                    partialNumber = (partialNumber * 10) + val

                    let neighbors = neighbors(row: rowIdx, col: colIdx)
                        .filter { gridIdx in
                            !self[gridIdx].isWholeNumber && self[gridIdx] != "."
                        }

                    adjacentSymbols.formUnion(neighbors)
                } else if partialNumber > 0 {
                    result.append((partialNumber, adjacentSymbols))
                    adjacentSymbols = Set()
                    partialNumber = 0
                }
            }

            return result
        }
    }
}

func part1(_ string: String) -> Int {
    let asCharacters = string.lines().map { Array($0) }
    let grid = Grid<Character>(asCharacters, connectivity: GridConnectivity.eightWay)


    return grid.numbersAndNeighboringSymbols()
        .filter {
            $0.1.count > 0
        }
        .map { $0.0 }
        .reduce(0, +)
}

verify([
    (testInput, 4361),
    (input, 532428)
], part1)

/**
 # --- Part Two ---

 The engineer finds the missing part and installs it in the engine! As the engine springs to life, you jump in the closest gondola, finally ready to ascend to the water source.

 You don't seem to be going very fast, though. Maybe something is still wrong? Fortunately, the gondola has a phone labeled "help", so you pick it up and the engineer answers.

 Before you can explain the situation, she suggests that you look out the window. There stands the engineer, holding a phone in one hand and waving with the other. You're going so slowly that you haven't even left the station. You exit the gondola.

 The missing part wasn't the only issue - one of the gears in the engine is wrong. A **gear** is any `*` symbol that is adjacent to **exactly two part numbers.** Its **gear ratio** is the result of multiplying those two numbers together.

 This time, you need to find the gear ratio of every gear and add them all up so that the engineer can figure out which gear needs to be replaced.

 Consider the same engine schematic again:

 ```
 467..114..
 ...*......
 ..35..633.
 ......#...
 617*......
 .....+.58.
 ..592.....
 ......755.
 ...$.*....
 .664.598..
 ```

 In this schematic, there are **two** gears. The first is in the top left; it has part numbers `467` and `35`, so its gear ratio is `16345`. The second gear is in the lower right; its gear ratio is `451490`. (The `*` adjacent to `617` is not a gear because it is only adjacent to one part number.) Adding up all of the gear ratios produces `467835`.

  **What is the sum of all of the gear ratios in your engine schematic?**
 */

func part2(_ string: String) -> Int {
    let asCharacters = string.lines().map { Array($0) }
    let grid = Grid<Character>(asCharacters, connectivity: GridConnectivity.eightWay)

    let gears = grid.numbersAndNeighboringSymbols()
        .reduce(into: [GridIndex: [Int]]()) { gears, numSyms in

            let asterisks = numSyms.1.filter { idx in
                grid[idx] == "*"
            }

            for idx in asterisks {
                gears[idx, default: []].append(numSyms.0)
            }
        }
        .filter {
            $0.value.count > 1
        }
        .mapValues {
            $0.reduce(1, *)
        }

    return gears.reduce(0) { $0 + $1.value }
}

verify([
    (testInput, 467835),
    (input, 84051670)
], part2)

//: [Next](@next)
