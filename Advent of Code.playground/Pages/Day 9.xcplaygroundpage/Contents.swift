//: [Previous](@previous)

/*:
 # Day 9: Explosives in Cyberspace

 Wandering around a secure area, you come across a datalink port to a new part of the network. After briefly scanning it for interesting files, you find one file in particular that catches your attention. It's compressed with an experimental format, but fortunately, the documentation for the format is nearby.

 The format compresses a sequence of characters. Whitespace is ignored. To indicate that some sequence should be repeated, a marker is added to the file, like `(10x2)`. To decompress this marker, take the subsequent `10` characters and repeat them `2` times. Then, continue reading the file **after** the repeated data. The marker itself is not included in the decompressed output.

 If parentheses or other characters appear within the data referenced by a marker, that's okay - treat it like normal data, not a marker, and then resume looking for markers after the decompressed section.

 For example:

 `ADVENT` contains no markers and decompresses to itself with no changes, resulting in a decompressed length of `6`.
 `A(1x5)BC` repeats only the `B` a total of `5` times, becoming `ABBBBBC` for a decompressed length of `7`.
 `(3x3)XYZ` becomes `XYZXYZXYZ` for a decompressed length of `9`.
 `A(2x2)BCD(2x2)EFG` doubles the `BC` and `EF`, becoming `ABCBCDEFEFG` for a decompressed length of `11`.
 `(6x1)(1x3)A` simply becomes `(1x3)A` - the `(1x3)` looks like a marker, but because it's within a data section of another marker, it is not treated any differently from the `A` that comes after it. It has a decompressed length of `6`.
 `X(8x2)(3x3)ABCY` becomes `X(3x3)ABC(3x3)ABCY` (for a decompressed length of `18`), because the decompressed data from the `(8x2)` marker (the `(3x3)ABC`) is skipped and not processed further.
 What is the **decompressed length** of the file (your puzzle input)? Don't count whitespace.
 */

import Foundation

func decompress(_ compressed: String) -> String {
    var result = ""
    var iterator = compressed.unicodeScalars.makeIterator()

    while true {
        guard let nextCharacter = iterator.next() else { break }

        if nextCharacter == "(" {
            var marker = ""

            while let markerCharacter = iterator.next() {
                if markerCharacter == ")" {
                    // found the end of the marker
                    var markerComponents = marker.components(separatedBy: "x")
                    guard let characterCount = Int(markerComponents[0], radix: 10), let repeatCount = Int(markerComponents[1], radix: 10) else {
                        fatalError("malformed marker: \(marker)")
                    }

                    var stringToRepeat = ""
                    for _ in 0..<characterCount {
                        if let next = iterator.next() {
                            stringToRepeat += String(next)
                        }
                    }

                    for _ in 0..<repeatCount {
                        result += stringToRepeat
                    }

                    break
                } else {
                    marker += String(markerCharacter)
                }
            }
        } else {
            result += String(nextCharacter)
        }
    }

    return result
}


assert(decompress("ADVENT") == "ADVENT")
assert(decompress("A(1x5)BC") == "ABBBBBC")
assert(decompress("(3x3)XYZ") == "XYZXYZXYZ")
assert(decompress("A(2x2)BCD(2x2)EFG") == "ABCBCDEFEFG")
assert(decompress("(6x1)(1x3)A") == "(1x3)A")
assert(decompress("X(8x2)(3x3)ABCY") == "X(3x3)ABC(3x3)ABCY")

let input = try readResourceFile("input.txt")

let decompressedInput = decompress(input)
assert(decompressedInput.unicodeScalars.count == 138735)



//: [Next](@next)
