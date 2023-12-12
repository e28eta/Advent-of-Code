//: [Previous](@previous)

import Foundation

/**
 # --- Day 8: Haunted Wasteland ---

 You're still riding a camel across Desert Island when you spot a sandstorm quickly approaching. When you turn to warn the Elf, she disappears before your eyes! To be fair, she had just finished warning you about **ghosts** a few minutes ago.

 One of the camel's pouches is labeled "maps" - sure enough, it's full of documents (your puzzle input) about how to navigate the desert. At least, you're pretty sure that's what they are; one of the documents contains a list of left/right instructions, and the rest of the documents seem to describe some kind of **network** of labeled nodes.

 It seems like you're meant to use the **left/right** instructions to **navigate the network**. Perhaps if you have the camel follow the same instructions, you can escape the haunted wasteland!

 After examining the maps for a bit, two nodes stick out: `AAA` and `ZZZ`. You feel like `AAA` is where you are now, and you have to follow the left/right instructions until you reach `ZZZ`.

 This format defines each **node** of the network individually. For example:

 ```
 RL

 AAA = (BBB, CCC)
 BBB = (DDD, EEE)
 CCC = (ZZZ, GGG)
 DDD = (DDD, DDD)
 EEE = (EEE, EEE)
 GGG = (GGG, GGG)
 ZZZ = (ZZZ, ZZZ)
 ```

 Starting with `AAA`, you need to **look up the next element** based on the next left/right instruction in your input. In this example, start with `AAA` and go **right** (`R`) by choosing the right element of `AAA`, `CCC`. Then, `L` means to choose the left element of `CCC`, `ZZZ`. By following the left/right instructions, you reach `ZZZ` in **2** steps.

 Of course, you might not find `ZZZ` right away. If you run out of left/right instructions, repeat the whole sequence of instructions as necessary: `RL` really means `RLRLRLRLRLRLRLRL...` and so on. For example, here is a situation that takes **6** steps to reach `ZZZ`:

 ```
 LLR

 AAA = (BBB, BBB)
 BBB = (AAA, ZZZ)
 ZZZ = (ZZZ, ZZZ)
 ```

 Starting at `AAA`, follow the left/right instructions. **How many steps are required to reach ZZZ?**
 */

let input = try readResourceFile("input.txt")

enum Direction: Character {
    case left = "L", right = "R"
}

struct Node {
    let label: String

    let left: String
    let right: String

    subscript(_ direction: Direction) -> String {
        return switch direction {
        case .left: left
        case .right: right
        }
    }
}

public struct Network {
    let directions: [Direction]
    let nodes: [String: Node]

    public func part1() -> Int {
        var node = nodes["AAA"]!

        for (offset, dir) in directions.cycled().enumerated() {
            node = nodes[node[dir]]!

            if node.label == "ZZZ" {
                return offset + 1
            }
        }

        // infinite directions, dead code
        return -1
    }
}

extension Network {
    public init(_ string: String) {
        let lines = string.lines()

        directions = lines[0]
            .compactMap(Direction.init)
        nodes = lines.suffix(from: 2)
            .compactMap(Node.init)
            .reduce(into: [:]) { d, n in
                d[n.label] = n
            }
    }
}

extension Node {
    public init?(_ line: some StringProtocol) {
        guard let (label, rest) = line.splitOnce(separator: " = ("),
              let (leftLabel, rightRest) = rest.splitOnce(separator: ", ") else {
            return nil
        }

        self.label = String(label)
        self.left = String(leftLabel)
        self.right = String(rightRest.prefix(3))
    }
}

verify([
    ("""
RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)
""", 2),
    ("""
LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)
""", 6),
    (input, 12083)
]) {
    Network($0).part1()
}

//: [Next](@next)
