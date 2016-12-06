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

/*:
 # Part Two

 Now that you've helpfully marked up their design documents, it occurs to you that triangles are specified in groups of three **vertically**. Each set of three numbers in a column specifies a triangle. Rows are unrelated.

 For example, given the following specification, numbers with the same hundreds digit would be part of the same triangle:

 ````
 101 301 501
 102 302 502
 103 303 503
 201 401 601
 202 402 602
 203 403 603
 ````
 In your puzzle input, and instead reading by columns, **how many** of the listed triangles are **possible**?
 */

extension Sequence {
    // Since we need three rows at a time to pick each triangle from, this iterates through Self (which is [[Int]]) as a sequence of tuples: ([Int], [Int], [Int])
    func threeAtATime() -> AnySequence<(Self.Iterator.Element, Self.Iterator.Element, Self.Iterator.Element)> {
        return AnySequence<(Self.Iterator.Element, Self.Iterator.Element, Self.Iterator.Element)> { () -> AnyIterator<(Self.Iterator.Element, Self.Iterator.Element, Self.Iterator.Element)> in
            var iterator = self.makeIterator()

            return AnyIterator {
                guard let first = iterator.next(),
                    let second = iterator.next(),
                    let third = iterator.next() else {
                        return nil
                }

                return (first, second, third)
            }
        }
    }
}

// Now that we have 3 rows, create zip3 to iterate through each column at a time
// this is probably overkill, since there are only 3 columns, but it'll work for any number of them
func zip3<T: Sequence, U: Sequence, V: Sequence>(_ t: T, _ u: U, _ v: V) -> AnySequence<(T.Iterator.Element, U.Iterator.Element, V.Iterator.Element)> {
    return AnySequence<(T.Iterator.Element, U.Iterator.Element, V.Iterator.Element)> { () -> AnyIterator<(T.Iterator.Element, U.Iterator.Element, V.Iterator.Element)> in
        var iterators = (t.makeIterator(), u.makeIterator(), v.makeIterator())

        return AnyIterator {
            guard let first = iterators.0.next(), let second = iterators.1.next(), let third = iterators.2.next() else {
                return nil
            }

            return (first, second, third)
        }
    }
}

// make sure the input is well-formed and we won't have a partials at the end
assert(sideLengths.count % 3 == 0)

let part2Answer = sideLengths.threeAtATime().flatMap {
    zip3($0.0, $0.1, $0.2).map {
        [$0.0, $0.1, $0.2] // convert each zipped element from a tuple to a 3-element array for isTriangle's use
    }
    }.filter(isTriangle).count

assert(part2Answer == 1921)



//: [Next](@next)
