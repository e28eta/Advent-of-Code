//: [Previous](@previous)

/*:
 # Day 6: Signals and Noise

 Something is jamming your communications with Santa. Fortunately, your signal is only partially jammed, and protocol in situations like this is to switch to a simple [repetition code](https://en.wikipedia.org/wiki/Repetition_code) to get the message through.

 In this model, the same message is sent repeatedly. You've recorded the repeating message signal (your puzzle input), but the data seems quite corrupted - almost too badly to recover. **Almost.**

 All you need to do is figure out which character is most frequent for each position. For example, suppose you had recorded the following messages:

 ````
 eedadn
 drvtee
 eandsr
 raavrd
 atevrs
 tsrnev
 sdttsa
 rasrtv
 nssdts
 ntnada
 svetve
 tesnvt
 vntsnd
 vrdear
 dvrsen
 enarar
 ````
 The most common character in the first column is `e`; in the second, `a`; in the third, `s`, and so on. Combining these characters returns the error-corrected message, `easter`.

 Given the recording in your puzzle input, **what is the error-corrected version** of the message being sent?
 */

import Foundation

//func correctErrors(_ input: [String]) -> String {
func buildFrequencies(_ input: [String]) -> [[Character: Int]] {
    typealias CharacterFrequency = [Character: Int]

    guard !input.isEmpty else { return [] }

    var frequencies = Array(repeating: CharacterFrequency(), count: input.first!.characters.count)

    for line in input {
        for (index, character) in line.characters.enumerated() {
            let currentCount = frequencies[index][character] ?? 0
            frequencies[index][character] = currentCount + 1
        }
    }

    return frequencies
}

enum ErrorCorrection {
    case MostCommonCharacter, LeastCommonCharacter
}

func correctErrors(_ frequencies: [[Character: Int]], errorCorrection: ErrorCorrection = .MostCommonCharacter) -> String {
    return frequencies.map {
        $0.sorted {
            if errorCorrection == .MostCommonCharacter {
                return $0.value > $1.value
            } else {
                return $0.value < $1.value
            }
            }.first.map {
                String($0.key)
            }!
        }.joined()
}

let example = ["eedadn", "drvtee", "eandsr", "raavrd", "atevrs", "tsrnev", "sdttsa", "rasrtv", "nssdts", "ntnada", "svetve", "tesnvt", "vntsnd", "vrdear", "dvrsen", "enarar"]
let exampleFrequencies = buildFrequencies(example)
assert(correctErrors(exampleFrequencies) == "easter")

let input = try readResourceFile("input.txt").trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
let part1Frequencies = buildFrequencies(input)
let part1Answer = correctErrors(part1Frequencies)

assert(part1Answer == "zcreqgiv")

/*:
 # Part Two ---

 Of course, that **would** be the message - if you hadn't agreed to use a **modified repetition code** instead.

 In this modified code, the sender instead transmits what looks like random data, but for each character, the character they actually want to send is **slightly less likely** than the others. Even after signal-jamming noise, you can look at the letter distributions in each column and choose the **least common** letter to reconstruct the original message.

 In the above example, the least common character in the first column is `a`; in the second, `d`, and so on. Repeating this process for the remaining characters produces the original message, `advent`.

 Given the recording in your puzzle input and this new decoding methodology, **what is the original message** that Santa is trying to send?
 */

let part2Example = correctErrors(exampleFrequencies, errorCorrection: .LeastCommonCharacter)
assert(part2Example == "advent")

let part2Answer = correctErrors(part1Frequencies, errorCorrection: .LeastCommonCharacter)
assert(part2Answer == "pljvorrk")

//: [Next](@next)
