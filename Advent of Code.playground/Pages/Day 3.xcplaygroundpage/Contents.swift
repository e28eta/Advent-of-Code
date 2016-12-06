//: [Previous](@previous)
/*:
 # Day 3: Squares With Three Sides

 Now that you can think clearly, you move deeper into the labyrinth of hallways and office furniture that makes up this part of Easter Bunny HQ. This must be a graphic design department; the walls are covered in specifications for triangles.

 Or are they?

 The design document gives the side lengths of each triangle it describes, but... `5 10 25`? Some of these aren't triangles. You can't help but mark the impossible ones.

 In a valid triangle, the sum of any two sides must be larger than the remaining side. For example, the "triangle" given above is impossible, because `5 + 10` is not larger than `25`.

 In your puzzle input, *how many* of the listed triangles are *possible*?
 */
import Foundation

func isTriangle(_ lengths: [Int]) -> Bool {
    assert(lengths.count == 3)
    let sorted = lengths.sorted()

    return sorted[0] + sorted[1] > sorted[2]
}

assert(isTriangle([5, 10, 25]) == false)

let input = try readResourceFile("input.txt").trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
let sideLengths = input.map { s -> [Int] in
    let lengths = s.components(separatedBy: .whitespaces).map {
        Int($0, radix: 10)!
    }
    assert(lengths.count == 3)

    return lengths
}

let part1Answer = sideLengths.filter(isTriangle).count
assert(part1Answer == 1050)



//: [Next](@next)
