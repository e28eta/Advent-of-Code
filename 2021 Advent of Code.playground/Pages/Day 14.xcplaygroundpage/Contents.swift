//: [Previous](@previous)

import Foundation

/**
 # --- Day 14: Extended Polymerization ---

 The incredible pressures at this depth are starting to put a strain on your submarine. The submarine has [polymerization](https://en.wikipedia.org/wiki/Polymerization) equipment that would produce suitable materials to reinforce the submarine, and the nearby volcanically-active caves should even have the necessary input elements in sufficient quantities.

 The submarine manual contains instructions for finding the optimal polymer formula; specifically, it offers a **polymer template** and a list of **pair insertion** rules (your puzzle input). You just need to work out what polymer would result after repeating the pair insertion process a few times.

 For example:

 ```
 NNCB

 CH -> B
 HH -> N
 CB -> H
 NH -> C
 HB -> C
 HC -> B
 HN -> C
 NN -> C
 BH -> H
 NC -> B
 NB -> B
 BN -> B
 BB -> N
 BC -> B
 CC -> N
 CN -> C
 ```

 The first line is the **polymer template** - this is the starting point of the process.

 The following section defines the **pair insertion** rules. A rule like `AB -> C` means that when elements `A` and `B` are immediately adjacent, element `C` should be inserted between them. These insertions all happen simultaneously.

 So, starting with the polymer template `NNCB`, the first step simultaneously considers all three pairs:

 - The first pair (`NN`) matches the rule `NN -> C`, so element `C` is inserted between the first `N` and the second `N`.
 - The second pair (`NC`) matches the rule `NC -> B`, so element `B` is inserted between the `N` and the `C`.
 - The third pair (`CB`) matches the rule `CB -> H`, so element `H` is inserted between the `C` and the `B`.

 Note that these pairs overlap: the second element of one pair is the first element of the next pair. Also, because all pairs are considered simultaneously, inserted elements are not considered to be part of a pair until the next step.

 After the first step of this process, the polymer becomes `NCNBCHB`.

 Here are the results of a few steps using the above rules:

 ```
 Template:     NNCB
 After step 1: NCNBCHB
 After step 2: NBCCNBBBCBHCB
 After step 3: NBBBCNCCNBBNBNBBCHBHHBCHB
 After step 4: NBBNBNBBCCNBCNCCNBBNBBNBBBNBBNBBCBHCBHHNHCBBCBHCB
 ```

 This polymer grows quickly. After step 5, it has length 97; After step 10, it has length 3073. After step 10, `B` occurs 1749 times, `C` occurs 298 times, `H` occurs 161 times, and `N` occurs 865 times; taking the quantity of the most common element (`B`, 1749) and subtracting the quantity of the least common element (`H`, 161) produces `1749 - 161 = 1588`.

 Apply 10 steps of pair insertion to the polymer template and find the most and least common elements in the result. **What do you get if you take the quantity of the most common element and subtract the quantity of the least common element?**
 */

let testInput = """
NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C
"""
let input = try readResourceFile("input.txt")

// don't actually need the full list... just count of each pair

struct Pair<T: Hashable>: Hashable {
    let left: T
    let right: T
}

extension Pair: CustomStringConvertible where T: CustomStringConvertible {
    var description: String {
        return "\(left.description)\(right.description)"
    }
}

struct Rule {
    let source: Pair<Character>
    let result: (Pair<Character>, Pair<Character>)

    init?(_ string: String) {
        guard let (sourceStr, newStr) = string.splitOnce(separator: " -> "),
              sourceStr.count == 2,
              let left = sourceStr.first,
              let right = sourceStr.last,
              newStr.count == 1,
              let newChar = newStr.first
        else {
            print("malformed Rule \(string)")
            return nil
        }

        source = Pair(left: left, right: right)
        result = (Pair(left: left, right: newChar),
                  Pair(left: newChar, right: right))
    }
}

struct Polymer {
    let template: [Character]
    let rules: [Pair<Character>: (Pair<Character>, Pair<Character>)]

    init(_ string: String) {
        guard let (template, ruleStr) = string.splitOnce(separator: "\n\n") else {
            fatalError("bad polymer input")
        }

        self.template = Array(template)
        rules = ruleStr.lines().compactMap(Rule.init).reduce(into: [:]) { rules, rule in
            rules[rule.source] = rule.result

        }
    }

    public func part1() -> Int {
        return run(steps: 10)
    }

    public func part2() -> Int {
        return run(steps: 40)
    }

    func run(steps: Int) -> Int {
        let templatePairs = zip(template, template.dropFirst())
        var pairCounts: [Pair<Character>: Int]
        = templatePairs.reduce(into: [:]) { counts, chars in
            counts[Pair(left: chars.0, right: chars.1), default: 0] += 1
        }

        // just track element counts separate from pair
        // counts instead of adjusting later & fixing up
        // for first / last element
        var elementCounts: [Character: Int] = template.reduce(into: [:]) { counts, char in
            counts[char, default: 0] += 1
        }

        for _ in (0 ..< steps) {
            pairCounts = pairCounts.reduce(into: [:]) { newCounts, pair in
                if let result = rules[pair.key] {
                    newCounts[result.0, default: 0] += pair.value
                    newCounts[result.1, default: 0] += pair.value

                    elementCounts[result.0.right, default: 0] += pair.value
                } else {
                    newCounts[pair.key, default: 0] += pair.value
                }
            }
        }

        let mostCommon = elementCounts.values.max()!
        let leastCommon = elementCounts.values.min()!

        return mostCommon - leastCommon
    }
}

verify([
    (testInput, 1588),
    (input, 2068)
]) {
    Polymer($0).part1()
}

/**
 # --- Part Two ---

 The resulting polymer isn't nearly strong enough to reinforce the submarine. You'll need to run more steps of the pair insertion process; a total of **40 steps** should do it.

 In the above example, the most common element is `B` (occurring `2192039569602` times) and the least common element is `H` (occurring `3849876073` times); subtracting these produces `2188189693529`.

 Apply **40** steps of pair insertion to the polymer template and find the most and least common elements in the result. **What do you get if you take the quantity of the most common element and subtract the quantity of the least common element?**
 */

verify([
    (testInput, 2188189693529),
    (input, 2158894777814)
]) {
    Polymer($0).part2()
}

//: [Next](@next)
