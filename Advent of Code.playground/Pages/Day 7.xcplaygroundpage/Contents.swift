//: [Previous](@previous)

/*:
 # Day 7: Internet Protocol Version 7

 While snooping around the local network of EBHQ, you compile a list of [IP addresses](https://en.wikipedia.org/wiki/IP_address) (they're IPv7, of course; [IPv6](https://en.wikipedia.org/wiki/IPv6) is much too limited). You'd like to figure out which IPs support **TLS** (transport-layer snooping).

 An IP supports TLS if it has an Autonomous Bridge Bypass Annotation, or **ABBA**. An ABBA is any four-character sequence which consists of a pair of two different characters followed by the reverse of that pair, such as `xyyx` or `abba`. However, the IP also must not have an ABBA within any hypernet sequences, which are contained by **square brackets**.

 For example:

 `abba[mnop]qrst` supports TLS (`abba` outside square brackets).
 `abcd[bddb]xyyx` does not support TLS (`bddb` is within square brackets, even though `xyyx` is outside square brackets).
 `aaaa[qwer]tyui` does not support TLS (`aaaa` is invalid; the interior characters must be different).
 `ioxxoj[asdfgh]zxcvbn` supports TLS (`oxxo` is outside square brackets, even though it's within a larger string).
 How many IPs in your puzzle input support TLS?
 */

import Foundation

let examples = ["abba[mnop]qrst", "abcd[bddb]xyyx", "aaaa[qwer]tyui", "ioxxoj[asdfgh]zxcvbn"]

let exampleResult = examples.map { example in
    example.characters.reduce(ParseState()) { $0.handlingCharacter($1) }.tlsState.supportsTLS
}

assert(exampleResult == [true, false, false, true])

let input = try readResourceFile("input.txt").components(separatedBy: .newlines)

let part1Answer = input.map { $0.characters.reduce(ParseState()) { $0.handlingCharacter($1) }}.filter { $0.tlsState.supportsTLS }.count
assert(part1Answer == 118)

/*:
 
 */

//: [Next](@next)
