//: [Previous](@previous)

import Foundation

/**
 # --- Day 4: Ceres Search ---

 "Looks like the Chief's not here. Next!" One of The Historians pulls out a device and pushes the only button on it. After a brief flash, you recognize the interior of the [Ceres monitoring station](https://adventofcode.com/2019/day/10)!

 As the search for the Chief continues, a small Elf who lives on the station tugs on your shirt; she'd like to know if you could help her with her **word search** (your puzzle input). She only has to find one word: `XMAS`.

 This word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words. It's a little unusual, though, as you don't merely need to find one instance of `XMAS` - you need to find all of them. Here are a few ways `XMAS` might appear, where irrelevant characters have been replaced with `.`:

 ```
 ..X...
 .SAMX.
 .A..A.
 XMAS.S
 .X....
 ```

 The actual word search will be full of letters instead. For example:

 ```
 MMMSXXMASM
 MSAMXMSMSA
 AMXSXMAAMM
 MSAMASMSMX
 XMASAMXAMM
 XXAMMXXAMA
 SMSMSASXSS
 SAXAMASAAA
 MAMMMXMMMM
 MXMXAXMASX
 ```

 In this word search, `XMAS` occurs a total of `18` times; here's the same word search again, but where letters not involved in any `XMAS` have been replaced with `.`:

 ```
 ....XXMAS.
 .SAMXMS...
 ...S..A...
 ..A.A.MS.X
 XMASAMX.MM
 X.....XA.A
 S.S.S.S.SS
 .A.A.A.A.A
 ..M.M.M.MM
 .X.X.XMASX
 ```

 Take a look at the little Elf's word search. **How many times does XMAS appear?**
 */

let input = try readResourceFile("input.txt")

class WordSearch {
    let grid: Grid<Character>

    init(_ string: String) {
        grid = Grid(string.lines().map(Array.init),
                    connectivity: GridConnectivity.eightWay)
    }
    
    func doesItMatch(_ target: some Collection<Character>,
                     from index: GridIndex,
                     direction: (Int, Int)) -> Bool {
        // ran out of characters left to find
        guard let next = target.first else { return true }

        guard let neighbor = index.advanced(by: direction,
                                            limitedTo: grid.endIndex),
              next == grid[neighbor] else {
            // either hit the edge of the grid, or neighbor doesn't match target
            return false
        }

        // look for the next letter
        return doesItMatch(target.dropFirst(),
                           from: neighbor,
                           direction: direction)
    }

    func xmasMatches() -> Int {
        let target: [Character] = ["X", "M", "A", "S"]
        var sum = 0

        for idx in grid.indices where grid[idx] == target.first! {
            for direction in GridConnectivity.eightWay.possibleNeighbors() {
                if doesItMatch(target.dropFirst(), from: idx, direction: direction) {
                    sum += 1
                }
            }
        }

        return sum
    }
}

verify([
    ("""
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
""", 18),
    (input, 2549)
]) {
    let search = WordSearch($0)
    return search.xmasMatches()
}

/**
 # --- Part Two ---

 The Elf looks quizzically at you. Did you misunderstand the assignment?

 Looking for the instructions, you flip over the word search to find that this isn't actually an `XMAS` puzzle; it's an `X-MAS` puzzle in which you're supposed to find two `MAS` in the shape of an `X`. One way to achieve that is like this:

 ```
 M.S
 .A.
 M.S
 ```

 Irrelevant characters have again been replaced with `.` in the above diagram. Within the `X`, each `MAS` can be written forwards or backwards.

 Here's the same example from before, but this time all of the `X-MAS`es have been kept instead:

 ```
 .M.S......
 ..A..MSMS.
 .M.S.MAA..
 ..A.ASMSM.
 .M.S.M....
 ..........
 S.S.S.S.S.
 .A.A.A.A..
 M.M.M.M.M.
 ..........
 ```

 In this example, an `X-MAS` appears `9` times.

 Flip the word search from the instructions back over to the word search side and try again. **How many times does an X-MAS appear?**
 */

extension Grid {
    public subscript(position: Index, direction: (Int, Int)) -> E? {
        guard let neighbor = position.advanced(
            by: direction,
            limitedTo: endIndex
        ) else { return nil }

        return self[neighbor]
    }
}

extension WordSearch {
    func x_masMatches() -> Int {
        var sum = 0
        let nw = (-1, -1), sw = (1, -1), ne = (-1, 1), se = (1, 1)

        for idx in grid.indices where grid[idx] == "A" {
            switch (grid[idx, nw], grid[idx, se], grid[idx, ne], grid[idx, sw]) {
            case ("M", "S", "M", "S"),
                ("M", "S", "S", "M"),
                ("S", "M", "M", "S"),
                ("S", "M", "S", "M"):
                sum += 1
            default: continue
            }
        }

        return sum
    }
}

verify([
    ("""
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
""", 9),
    (input, 2003)
]) {
    let search = WordSearch($0)
    return search.x_masMatches()
}
//: [Next](@next)
