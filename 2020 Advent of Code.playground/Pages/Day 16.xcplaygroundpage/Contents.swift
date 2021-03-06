//: [Previous](@previous)

import Foundation

/**
 --- Day 16: Ticket Translation ---

 As you're walking to yet another connecting flight, you realize that one of the legs of your re-routed trip coming up is on a high-speed train. However, the train ticket you were given is in a language you don't understand. You should probably figure out what it says before you get to the train station after the next flight.

 Unfortunately, you can't actually **read** the words on the ticket. You can, however, read the numbers, and so you figure out the **fields these tickets must have** and **the valid ranges** for values in those fields.

 You collect the **rules for ticket fields,** the **numbers on your ticket,** and the **numbers on other nearby tickets** for the same train service (via the airport security cameras) together into a single document you can reference (your puzzle input).

 The **rules for ticket fields** specify a list of fields that exist **somewhere** on the ticket and the **valid ranges of values** for each field. For example, a rule like `class: 1-3 or 5-7` means that one of the fields in every ticket is named `class` and can be any value in the ranges `1-3` or `5-7` (inclusive, such that `3` and `5` are both valid in this field, but `4` is not).

 Each ticket is represented by a single line of comma-separated values. The values are the numbers on the ticket in the order they appear; every ticket has the same format. For example, consider this ticket:

 ```
 .--------------------------------------------------------.
 | ????: 101    ?????: 102   ??????????: 103     ???: 104 |
 |                                                        |
 | ??: 301  ??: 302             ???????: 303      ??????? |
 | ??: 401  ??: 402           ???? ????: 403    ????????? |
 '--------------------------------------------------------'
 ```

 Here, `?` represents text in a language you don't understand. This ticket might be represented as `101,102,103,104,301,302,303,401,402,403`; of course, the actual train tickets you're looking at are **much** more complicated. In any case, you've extracted just the numbers in such a way that the first number is always the same specific field, the second number is always a different specific field, and so on - you just don't know what each position actually means!

 Start by determining which tickets are **completely invalid;** these are tickets that contain values which **aren't valid for any field.** Ignore **your ticket** for now.

 For example, suppose you have the following notes:

 ```
 class: 1-3 or 5-7
 row: 6-11 or 33-44
 seat: 13-40 or 45-50

 your ticket:
 7,1,14

 nearby tickets:
 7,3,47
 40,4,50
 55,2,20
 38,6,12
 ```

 It doesn't matter which position corresponds to which field; you can identify invalid **nearby tickets** by considering only whether tickets contain values that are **not valid for any field.** In this example, the values on the first **nearby ticket** are all valid for at least one field. This is not true of the other three **nearby tickets:** the values `4`, `55`, and `12` are are not valid for any field. Adding together all of the invalid values produces your **ticket scanning error rate:** `4 + 55 + 12` = `71`.

 Consider the validity of the **nearby tickets** you scanned. **What is your ticket scanning error rate?**
 */

struct Ticket {
    let values: [Int]

    init<S: StringProtocol>(_ string: S) {
        values = string.split(separator: ",").compactMap(Int.init)
    }
}

struct Rule: Hashable {
    let label: String
    let validValues: MultipleClosedRanges<Int>

    init?(_ string: String) {
        guard let (label, rangeString) = string.splitOnce(separator: ": ") else {
            return nil
        }
        self.label = String(label)
        let ranges = rangeString.components(separatedBy: " or ").compactMap { s -> ClosedRange<Int>? in
            guard let (first, second) = s.splitOnce(separator: "-"),
                  let lower = Int(first),
                  let upper = Int(second) else { return nil }

            return (lower...upper)
        }
        validValues = MultipleClosedRanges(ranges)
    }

    static func == (lhs: Rule, rhs: Rule) -> Bool {
        // good enough
        return lhs.label == rhs.label
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
    }
}

struct TicketDocument {
    let rules: [Rule]
    let myTicket: Ticket
    let nearbyTickets: [Ticket]
    let validNearbyTickets: [Ticket]
    let scanningErrorRate: Int

    init?(_ string: String) {
        guard let (ruleString, allTicketString) = string.splitOnce(separator: "\n\nyour ticket:\n"),
              let (myTicketString, nearbyTicketsString) = allTicketString.splitOnce(separator: "\n\nnearby tickets:\n")
        else { return nil }

        rules = ruleString.lines().compactMap(Rule.init)
        myTicket = Ticket(myTicketString)
        nearbyTickets = nearbyTicketsString.lines().map(Ticket.init)

        let allValidValues = MultipleClosedRanges(rules.flatMap(\.validValues.combinedRanges))

        validNearbyTickets = nearbyTickets.filter { (ticket) in
            ticket.values.allSatisfy(allValidValues.contains)
        }

        scanningErrorRate = nearbyTickets.lazy
            .flatMap(\.values)
            .filter { !allValidValues.contains($0) }
            .reduce(0, +)
    }

    func ticketScanningErrorRate() -> Int {
        return scanningErrorRate
    }
}

struct MultipleClosedRanges<U> where U: Strideable {
    let combinedRanges: [ClosedRange<U>]

    init(_ ranges: [ClosedRange<U>]) {
        combinedRanges = ranges.sorted {
            $0.lowerBound < $1.lowerBound
        }
        .reduce(into: []) { (result, range) in
            guard let previousRange = result.last else {
                // first range encountered
                result.append(range)
                return
            }

            if previousRange.upperBound < range.lowerBound {
                // there's a gap. Add this range as the new one to update
                result.append(range)
            } else if previousRange.upperBound < range.upperBound {
                // update last range to include the new elements from the overlapping range
                result[result.endIndex - 1] = (previousRange.lowerBound ... range.upperBound)
            }
        }
    }

    func contains(_ value: U) -> Bool {
        return nil != combinedRanges.first { range in
            range.contains(value)
        }
    }
}

let exampleInput = TicketDocument("""
class: 1-3 or 5-7
row: 6-11 or 33-44
seat: 13-40 or 45-50

your ticket:
7,1,14

nearby tickets:
7,3,47
40,4,50
55,2,20
38,6,12
""")
let input = try TicketDocument(readResourceFile("input.txt"))


verify([
    (exampleInput, 71),
    (input, 19087),
]) {
    $0?.ticketScanningErrorRate() ?? -1
}

/**
 --- Part Two ---

 Now that you've identified which tickets contain invalid values, **discard those tickets entirely.** Use the remaining valid tickets to determine which field is which.

 Using the valid ranges for each field, determine what order the fields appear on the tickets. The order is consistent between all tickets: if seat is the third field, it is the third field on every ticket, including **your ticket.**

 For example, suppose you have the following notes:

 ```
 class: 0-1 or 4-19
 row: 0-5 or 8-19
 seat: 0-13 or 16-19

 your ticket:
 11,12,13

 nearby tickets:
 3,9,18
 15,1,5
 5,14,9
 ```

 Based on the **nearby tickets** in the above example, the first position must be `row`, the second position must be `class`, and the third position must be `seat`; you can conclude that in **your ticket**, `class` is `12`, `row` is `11`, and `seat` is `13`.

 Once you work out which field is which, look for the six fields on **your ticket** that start with the word `departure`. **What do you get if you multiply those six values together?**
 */

extension TicketDocument {
    func fieldOrdering() -> [Rule] {
        var possibleFieldOrderings = myTicket.values.indices.map { index -> Set<Rule> in
            rules.filter { rule in
                // this rule could apply if every valid ticket conforms to it
                validNearbyTickets.allSatisfy { ticket in
                    rule.validValues.contains(ticket.values[index])
                }
            }.reduce(into: Set()) {
                $0.insert($1)
            }
        }

        // presumably now I have some Rules that've been uniquely identified,
        // use those to figure out what's no longer possible for the rest
        repeat {
            let definitivelyIdentifiedRules = possibleFieldOrderings.reduce(into: Set<Rule>()) { set, rules in
                guard rules.count == 1, let rule = rules.first else { return }
                set.insert(rule)
            }

            possibleFieldOrderings = possibleFieldOrderings.map {
                guard $0.count > 1 else { return $0 }
                return $0.subtracting(definitivelyIdentifiedRules)
            }
        } while (!possibleFieldOrderings.allSatisfy({ $0.count == 1 }))

        return possibleFieldOrderings.flatMap { $0 }
    }

    func partTwo() -> Int {
        return fieldOrdering()
            .enumerated()
            .filter { $0.element.label.hasPrefix("departure") }
            .map { myTicket.values[$0.offset] }
            .reduce(1, *)
    }
}

let exampleTwo = TicketDocument("""
class: 0-1 or 4-19
row: 0-5 or 8-19
seat: 0-13 or 16-19

your ticket:
11,12,13

nearby tickets:
3,9,18
15,1,5
5,14,9
""")

verify([
    (exampleTwo, ["row", "class", "seat"]),
]) {
    $0?.fieldOrdering().map(\.label) ?? [String]()
}

verify([
    (input, 1382443095281)
]) {
    $0?.partTwo() ?? -1
}

//: [Next](@next)
