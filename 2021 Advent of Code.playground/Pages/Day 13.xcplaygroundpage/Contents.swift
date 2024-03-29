//: [Previous](@previous)

import Foundation

/**
 # --- Day 13: Transparent Origami ---

 You reach another volcanically active part of the cave. It would be nice if you could do some kind of thermal imaging so you could tell ahead of time which caves are too hot to safely enter.

 Fortunately, the submarine seems to be equipped with a thermal camera! When you activate it, you are greeted with:

 ```
 Congratulations on your purchase! To activate this infrared thermal imaging camera system, please enter the code found on page 1 of the manual.
 ```

 Apparently, the Elves have never used this feature. To your surprise, you manage to find the manual; as you go to open it, page 1 falls out. It's a large sheet of [transparent paper](https://en.wikipedia.org/wiki/Transparency_(projection))! The transparent paper is marked with random dots and includes instructions on how to fold it up (your puzzle input). For example:

 ```
 6,10
 0,14
 9,10
 0,3
 10,4
 4,11
 6,0
 6,12
 4,1
 0,13
 10,12
 3,4
 3,0
 8,4
 1,10
 2,14
 8,10
 9,0

 fold along y=7
 fold along x=5
 ```

 The first section is a list of dots on the transparent paper. `0,0` represents the top-left coordinate. The first value, `x`, increases to the right. The second value, `y`, increases downward. So, the coordinate `3,0` is to the right of `0,0`, and the coordinate `0,7` is below `0,0`. The coordinates in this example form the following pattern, where `#` is a dot on the paper and `.` is an empty, unmarked position:

 ```
 ...#..#..#.
 ....#......
 ...........
 #..........
 ...#....#.#
 ...........
 ...........
 ...........
 ...........
 ...........
 .#....#.##.
 ....#......
 ......#...#
 #..........
 #.#........
 ```

 Then, there is a list of **fold instructions.** Each instruction indicates a line on the transparent paper and wants you to fold the paper **up** (for horizontal `y=...` lines) or **left** (for vertical `x=...` lines). In this example, the first fold instruction is `fold along y=7`, which designates the line formed by all of the positions where `y` is `7` (marked here with `-`):

 ```
 ...#..#..#.
 ....#......
 ...........
 #..........
 ...#....#.#
 ...........
 ...........
 -----------
 ...........
 ...........
 .#....#.##.
 ....#......
 ......#...#
 #..........
 #.#........
 ```

 Because this is a horizontal line, fold the bottom half **up**. Some of the dots might end up overlapping after the fold is complete, but dots will never appear exactly on a fold line. The result of doing this fold looks like this:

 ```
 #.##..#..#.
 #...#......
 ......#...#
 #...#......
 .#.#..#.###
 ...........
 ...........
 ```

 Now, only `17` dots are visible.

 Notice, for example, the two dots in the bottom left corner before the transparent paper is folded; after the fold is complete, those dots appear in the top left corner (at 0,0 and 0,1). Because the paper is transparent, the dot just below them in the result (at 0,3) remains visible, as it can be seen through the transparent paper.

 Also notice that some dots can end up **overlapping;** in this case, the dots merge together and become a single dot.

 The second fold instruction is `fold along x=5`, which indicates this line:

 ```
 #.##.|#..#.
 #...#|.....
 .....|#...#
 #...#|.....
 .#.#.|#.###
 .....|.....
 .....|.....
 ```

 Because this is a vertical line, fold **left:**

 ```
 #####
 #...#
 #...#
 #...#
 #####
 .....
 .....
 ```

 The instructions made a square!

 The transparent paper is pretty big, so for now, focus on just completing the first fold. After the first fold in the example above, `17` dots are visible - dots that end up overlapping after the fold is completed count as a single dot.

  **How many dots are visible after completing just the first fold instruction on your transparent paper?**
 */

let testInput = """
6,10
0,14
9,10
0,3
10,4
4,11
6,0
6,12
4,1
0,13
10,12
3,4
3,0
8,4
1,10
2,14
8,10
9,0

fold along y=7
fold along x=5
"""
let input = try readResourceFile("input.txt")

public struct Fold {
    enum Axis: String {
        case x, y
    }
    let axis: Axis
    let value: Int

    public init?(_ line: String) {
        let components = line.split(separator: " ")

        guard line.hasPrefix("fold along "),
              components.count == 3,
              let (axisStr, amountStr) = components[2].splitOnce(separator: "="),
              let axis = Axis(rawValue: String(axisStr)),
              let value = Int(amountStr) else {
            return nil
        }

        self.axis = axis
        self.value = value
    }

    public func translate(point: Point) -> Point {
        switch axis {
        case .x:
            if point.x > value {
                let delta = point.x - value
                return Point(x: value - delta, y: point.y)
            }
        case .y:
            if point.y > value {
                let delta = point.y - value
                return Point(x: point.x, y: value - delta)
            }
        }
        return point
    }
}

public struct Transparency {
    let points: [Point]
    let folds: [Fold]

    public init?(_ string: String) {
        guard let (pointsStr, foldsStr) = string.splitOnce(separator: "\n\n") else {
            return nil
        }
        points = pointsStr.lines().compactMap(Point.init)
        folds = foldsStr.lines().compactMap(Fold.init)
    }

    public func part1() -> Int {
        return Set(points.map({ folds[0].translate(point: $0) }))
            .count
    }
}

verify([
    (testInput, 17),
    (input, 618)
]) {
    let t = Transparency($0)
    return t?.part1() ?? -1
}

/**
 # --- Part Two ---

 Finish folding the transparent paper according to the instructions. The manual says the code is always **eight capital letters.**

  **What code do you use to activate the infrared thermal imaging camera system?**
 */

extension Transparency {
    public func part2() {
        let finalPoints = folds.reduce(Set(points)) { points, fold in
            return points.reduce(into: Set()) { s, p in
                s.insert(fold.translate(point: p))
            }
        }

        let maxX = finalPoints.map(\.x).max()!
        let maxY = finalPoints.map(\.y).max()!

        for y in (0...maxY) {
            let line = (0...maxX).map { x in
                finalPoints.contains(Point(x: x, y: y)) ? "#" : " "
            }.joined()

            print(line)
        }
    }
}

print("test output:")
Transparency(testInput)?.part2() // a square (or capital O?)

print("part2 output:")
Transparency(input)?.part2() // ALREKFKU

//: [Next](@next)
