//: [Previous](@previous)

import Foundation

/**
 --- Day 10: Adapter Array ---

 Patched into the aircraft's data port, you discover weather forecasts of a massive tropical storm. Before you can figure out whether it will impact your vacation plans, however, your device suddenly turns off!

 Its battery is dead.

 You'll need to plug it in. There's only one problem: the charging outlet near your seat produces the wrong number of **jolts.** Always prepared, you make a list of all of the joltage adapters in your bag.

 Each of your joltage adapters is rated for a specific **output joltage** (your puzzle input). Any given adapter can take an input `1`, `2`, or `3` jolts **lower** than its rating and still produce its rated output joltage.

 In addition, your device has a built-in joltage adapter rated for `3` jolts **higher** than the highest-rated adapter in your bag. (If your adapter list were `3`, `9`, and `6`, your device's built-in adapter would be rated for `12` jolts.)

 Treat the charging outlet near your seat as having an effective joltage rating of `0`.

 Since you have some time to kill, you might as well test all of your adapters. Wouldn't want to get to your resort and realize you can't even charge your device!

 If you **use every adapter in your bag** at once, what is the distribution of joltage differences between the charging outlet, the adapters, and your device?

 For example, suppose that in your bag, you have adapters with the following joltage ratings:

 ```
 16
 10
 15
 5
 1
 11
 7
 19
 6
 12
 4
 ```

 With these adapters, your device's built-in joltage adapter would be rated for `19` + `3` = `22` jolts, `3` higher than the highest-rated adapter.

 Because adapters can only connect to a source `1`-`3` jolts lower than its rating, in order to use every adapter, you'd need to choose them like this:

 - The charging outlet has an effective rating of `0` jolts, so the only adapters that could connect to it directly would need to have a joltage rating of `1`, `2`, or `3` jolts. Of these, only one you have is an adapter rated `1` jolt (difference of `1`).
 - From your `1`-jolt rated adapter, the only choice is your `4`-jolt rated adapter (difference of `3`).
 - From the `4`-jolt rated adapter, the adapters rated `5`, `6`, or `7` are valid choices. However, in order to not skip any adapters, you have to pick the adapter rated `5` jolts (difference of `1`).
 - Similarly, the next choices would need to be the adapter rated `6` and then the adapter rated `7` (with difference of `1` and `1`).
 - The only adapter that works with the `7`-jolt rated adapter is the one rated `10` jolts (difference of `3`).
 - From `10`, the choices are `11` or `12`; choose `11` (difference of `1`) and then `12` (difference of `1`).
 - After `12`, only valid adapter has a rating of `15` (difference of `3`), then `16` (difference of `1`), then `19` (difference of `3`).
 - Finally, your device's built-in adapter is always `3` higher than the highest adapter, so its rating is `22` jolts (always a difference of `3`).

 In this example, when using every adapter, there are `7` differences of `1` jolt and `5` differences of `3` jolts.

 Here is a larger example:

 ```
 28
 33
 18
 42
 31
 14
 46
 20
 48
 47
 24
 23
 49
 45
 19
 38
 39
 11
 1
 32
 25
 35
 8
 17
 7
 9
 4
 2
 34
 10
 3
 ```

 In this larger example, in a chain that uses all of the adapters, there are `22` differences of `1` jolt and `10` differences of `3` jolts.

 Find a chain that uses all of your adapters to connect the charging outlet to your device's built-in adapter and count the joltage differences between the charging outlet, the adapters, and your device. **What is the number of 1-jolt differences multiplied by the number of 3-jolt differences?**
 */

let example1 = """
16
10
15
5
1
11
7
19
6
12
4
""".lines().compactMap(Int.init).sorted()

let example2 = """
28
33
18
42
31
14
46
20
48
47
24
23
49
45
19
38
39
11
1
32
25
35
8
17
7
9
4
2
34
10
3
""".lines().compactMap(Int.init).sorted()

let input = try readResourceFile("input.txt").lines().compactMap(Int.init).sorted()

func distribution(_ sorted: [Int]) -> (Int, Int, Int) {
    var differences = [0, 0, 0, 0]
    let joltages = [0] + sorted + [sorted.last! + 3]

    for (lesser, greater) in zip(joltages, joltages.dropFirst()) {
        differences[greater - lesser] += 1
    }

    return (differences[1], differences[2], differences[3])
}

verify([
    (example1, 35),
    (example2, 220),
    (input, 2201)
]) {
    let (one, _, three) = distribution($0)
    return one * three
}

/**
 --- Part Two ---

 To completely determine whether you have enough adapters, you'll need to figure out how many different ways they can be arranged. Every arrangement needs to connect the charging outlet to your device. The previous rules about when adapters can successfully connect still apply.

 The first example above (the one that starts with `16`, `10`, `15`) supports the following arrangements:

 ```
 (0), 1, 4, 5, 6, 7, 10, 11, 12, 15, 16, 19, (22)
 (0), 1, 4, 5, 6, 7, 10, 12, 15, 16, 19, (22)
 (0), 1, 4, 5, 7, 10, 11, 12, 15, 16, 19, (22)
 (0), 1, 4, 5, 7, 10, 12, 15, 16, 19, (22)
 (0), 1, 4, 6, 7, 10, 11, 12, 15, 16, 19, (22)
 (0), 1, 4, 6, 7, 10, 12, 15, 16, 19, (22)
 (0), 1, 4, 7, 10, 11, 12, 15, 16, 19, (22)
 (0), 1, 4, 7, 10, 12, 15, 16, 19, (22)
 ```

 (The charging outlet and your device's built-in adapter are shown in parentheses.) Given the adapters from the first example, the total number of arrangements that connect the charging outlet to your device is `8`.

 The second example above (the one that starts with `28`, `33`, `18`) has many arrangements. Here are a few:

 ```
 (0), 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20, 23, 24, 25, 28, 31,
 32, 33, 34, 35, 38, 39, 42, 45, 46, 47, 48, 49, (52)

 (0), 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20, 23, 24, 25, 28, 31,
 32, 33, 34, 35, 38, 39, 42, 45, 46, 47, 49, (52)

 (0), 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20, 23, 24, 25, 28, 31,
 32, 33, 34, 35, 38, 39, 42, 45, 46, 48, 49, (52)

 (0), 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20, 23, 24, 25, 28, 31,
 32, 33, 34, 35, 38, 39, 42, 45, 46, 49, (52)

 (0), 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20, 23, 24, 25, 28, 31,
 32, 33, 34, 35, 38, 39, 42, 45, 47, 48, 49, (52)

 (0), 3, 4, 7, 10, 11, 14, 17, 20, 23, 25, 28, 31, 34, 35, 38, 39, 42, 45,
 46, 48, 49, (52)

 (0), 3, 4, 7, 10, 11, 14, 17, 20, 23, 25, 28, 31, 34, 35, 38, 39, 42, 45,
 46, 49, (52)

 (0), 3, 4, 7, 10, 11, 14, 17, 20, 23, 25, 28, 31, 34, 35, 38, 39, 42, 45,
 47, 48, 49, (52)

 (0), 3, 4, 7, 10, 11, 14, 17, 20, 23, 25, 28, 31, 34, 35, 38, 39, 42, 45,
 47, 49, (52)

 (0), 3, 4, 7, 10, 11, 14, 17, 20, 23, 25, 28, 31, 34, 35, 38, 39, 42, 45,
 48, 49, (52)
 ```

 In total, this set of adapters can connect the charging outlet to your device in `19208` distinct arrangements.

 You glance back down at your bag and try to remember why you brought so many adapters; there must be **more than a trillion** valid ways to arrange them! Surely, there must be an efficient way to count the arrangements.

 \**What is the total number of distinct ways you can arrange the adapters to connect the charging outlet to your device?**
 */

/*
 Shortcut! According to my adapter distributions, they're all either 1 or 3 apart.
 Figure out how many adapters in a row are 1 apart, and that gives the number of combos.
 First & last must be included, because the sequence before and sequence after are 3 away.

 3 in a row: 2x; 0, 1
 4 in a row: 4x; 00, 01, 10, 11
 5 in a row: 7x; not 000

 Tried to work out a pattern. And then took another shortcut, and discovered my input
 never has >5 in a row 🤦‍♂️
 6 in a row: 13; can't have 0000, 0001, 1000, but any other combo
 7 in a row: can't have 00000, 00001, 10000, 00011, 00010, 10001, 11000, 01000. 32 - (1 + 2 + 5) = 24
 8 in a row: can't have 000000, 000001, 100000, 000011, 000010, 100001, 110000, 010000, 000100, 000101, 000110, 000111, 100010, 100011, 110001, 010001, 111000, 011000, 101000, 001000
 64 - (1 + 2 + 5 + 12) = 44
 */

func distinctWays(_ sorted: [Int]) -> Int {
    let joltages = [0] + sorted + [sorted.last! + 3]

    return zip(joltages, joltages.dropFirst()).reduce(into: [[]]) { (arrs, nums) in
        arrs[arrs.endIndex - 1].append(nums.0)
        let difference = nums.1 - nums.0
        switch difference {
        case 1:
            break
        case 3:
            arrs.append([])
        default:
            fatalError("unhandled difference amount \(difference)")
        }
    }
    .map(\.count)
    .reduce(1) { product, consecutiveSeqLength in
        switch consecutiveSeqLength {
        case 0...2:
            return product
        case 3:
            return product * 2
        case 4:
            return product * 4
        case 5:
            return product * 7
        default:
            fatalError("unhandled sequence length \(consecutiveSeqLength)")
        }
    }
}

verify([
    (example1, 8),
    (example2, 19208),
    (input, 169255295254528)
], distinctWays)

//: [Next](@next)
