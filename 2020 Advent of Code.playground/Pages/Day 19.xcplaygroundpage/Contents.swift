//: [Previous](@previous)

import Foundation

/**
 --- Day 19: Monster Messages ---

 You land in an airport surrounded by dense forest. As you walk to your high-speed train, the Elves at the Mythical Information Bureau contact you again. They think their satellite has collected an image of a **sea monster!** Unfortunately, the connection to the satellite is having problems, and many of the messages sent back from the satellite have been corrupted.

 They sent you a list of **the rules valid messages should obey** and a list of **received messages** they've collected so far (your puzzle input).

 The **rules for valid messages** (the top part of your puzzle input) are numbered and build upon each other. For example:

 ```
 0: 1 2
 1: "a"
 2: 1 3 | 3 1
 3: "b"
 ```

 Some rules, like `3: "b"`, simply match a single character (in this case, `b`).

 The remaining rules list the sub-rules that must be followed; for example, the rule `0: 1 2` means that to match rule `0`, the text being checked must match rule `1`, and the text after the part that matched rule `1` must then match rule `2`.

 Some of the rules have multiple lists of sub-rules separated by a pipe (`|`). This means that **at least one** list of sub-rules must match. (The ones that match might be different each time the rule is encountered.) For example, the rule `2: 1 3 | 3 1` means that to match rule `2`, the text being checked must match rule `1` followed by rule `3` or it must match rule `3` followed by rule `1`.

 Fortunately, there are no loops in the rules, so the list of possible matches will be finite. Since rule `1` matches `a` and rule `3` matches `b`, rule `2` matches either `ab` or `ba`. Therefore, rule `0` matches `aab` or `aba`.

 Here's a more interesting example:

 ```
 0: 4 1 5
 1: 2 3 | 3 2
 2: 4 4 | 5 5
 3: 4 5 | 5 4
 4: "a"
 5: "b"
 ```

 Here, because rule `4` matches `a` and rule `5` matches `b`, rule `2` matches two letters that are the same (`aa` or `bb`), and rule `3` matches two letters that are different (`ab` or `ba`).

 Since rule `1` matches rules `2` and `3` once each in either order, it must match two pairs of letters, one pair with matching letters and one pair with different letters. This leaves eight possibilities: `aaab`, `aaba`, `bbab`, `bbba`, `abaa`, `abbb`, `baaa`, or `babb`.

 Rule `0`, therefore, matches `a` (rule `4`), then any of the eight options from rule `1`, then `b` (rule `5`): `aaaabb`, `aaabab`, `abbabb`, `abbbab`, `aabaab`, `aabbbb`, `abaaab`, or `ababbb`.

 The **received messages** (the bottom part of your puzzle input) need to be checked against the rules so you can determine which are valid and which are corrupted. Including the rules and the messages together, this might look like:

 ```
 0: 4 1 5
 1: 2 3 | 3 2
 2: 4 4 | 5 5
 3: 4 5 | 5 4
 4: "a"
 5: "b"

 ababbb
 bababa
 abbbab
 aaabbb
 aaaabbb
 ```

 Your goal is to determine **the number of messages that completely match rule 0.** In the above example, `ababbb` and `abbbab` match, but `bababa`, `aaabbb`, and `aaaabbb` do not, producing the answer `2`. The whole message must match all of rule `0`; there can't be extra unmatched characters in the message. (For example, `aaaabbb` might appear to match rule `0` above, but it has an extra unmatched `b` on the end.)

 \**How many messages completely match rule 0?**
 */

indirect enum Rule {
    case sequence([Int])
    case alternatives([Int], [Int])
    case literal(Character)

    init?(_ string: Substring) {
        if string.hasPrefix("\"") {
            guard let character = string.dropFirst().first else { return nil }

            self = .literal(character)
        } else if string.contains("|") {
            guard let (first, second) = string.splitOnce(separator: " | ") else { return nil }

            self = .alternatives(first.split(separator: " ").compactMap(Int.init),
                                 second.split(separator: " ").compactMap(Int.init))
        } else {
            self = .sequence(string.split(separator: " ").compactMap(Int.init))
        }
    }

    func nfaStates(_ rules: [Int: Rule]) -> (start: NFAState, final: NFAState) {
        let start = NFAState(), final = NFAState()

        switch self {
        case .literal(let char):
            start.transition = .labeled(char, final)
        case .sequence(let ruleNumbers):
            ruleNumbers.map { ruleNumber in
                rules[ruleNumber]!.nfaStates(rules)
            }
            .reduce(start) { (previous, nfa) in
                previous.transition = .unlabeled(nfa.start)
                return nfa.final
            }
            .transition = .unlabeled(final)
        case .alternatives(let optionANumbers, let optionBNumbers):
            let optionAStates = optionANumbers.map { rules[$0]!.nfaStates(rules) }
            let optionBStates = optionBNumbers.map { rules[$0]!.nfaStates(rules) }

            optionAStates.reversed().reduce(final) { previous, state in
                state.final.transition = .unlabeled(previous)
                return state.start
            }
            optionBStates.reversed().reduce(final) { previous, state in
                state.final.transition = .unlabeled(previous)
                return state.start
            }
            start.transition = .unlabeled(optionAStates.first!.start, optionBStates.first!.start)
        }

        return (start: start, final: final)
    }
}

class NFAState: Hashable {
    // Pretty sure I want/need reference semantics for algos I'm seeing

    enum Edge {
        case none
        case unlabeled(NFAState, NFAState? = nil)
        case labeled(Character, NFAState)
    }

    var transition: Edge = .none


    static func == (lhs: NFAState, rhs: NFAState) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    /// All states reachable from this state (including this state), via epsilon transition
    func epsilonClosure() -> Set<NFAState> {
        var result: Set<NFAState> = [self]

        switch transition {
        case .unlabeled(let a, let b):
            result.formUnion(a.epsilonClosure()
                                .union(b?.epsilonClosure() ?? []))
        case .none, .labeled:
            break
        }

        return result
    }

    /// State reachable via character, or nil
    func transition(_ character: Character) -> NFAState? {
        if case let .labeled(char, next) = self.transition, char == character {
            return next
        }
        return nil
    }
}

struct NondeterministicFiniteAutomaton {
    let initialState: NFAState
    let acceptingStates: Set<NFAState>
    let alphabet: Set<Character>

    init(initialState: NFAState, acceptingStates: Set<NFAState>, alphabet: Set<Character>) {
        self.initialState = initialState
        self.acceptingStates = acceptingStates
        self.alphabet = alphabet
    }
}

class DFAState {
    let isFinal: Bool
    var transitions: [Character: DFAState] = [:]

    init(isFinal: Bool) {
        self.isFinal = isFinal
    }
}

struct DeterministicFiniteAutomaton {
    let initialState: DFAState
    let alphabet: Set<Character>

    init(_ nfa: NondeterministicFiniteAutomaton) {
        self.alphabet = nfa.alphabet
        // p51
        let q0 = nfa.initialState.epsilonClosure()
        var Q = Set([q0])
        var worklist = [q0]
        var transitions: [Set<NFAState>: [Character: Set<NFAState>]] = [:]

        while let q = worklist.popLast() {
            transitions[q] = [:]
            for char in alphabet {
                // find all the states reachable from q via char
                let t = q.compactMap { state in state.transition(char) }
                    .reduce(into: Set()) { $0.formUnion($1.epsilonClosure()) }
                // add to transition map
                transitions[q]![char] = t

                // is this a new state that needs to be explored?
                if !Q.contains(t) {
                    Q.insert(t)
                    worklist.append(t)
                }
            }
        }

        let dfa = Q.reduce(into: [:]) { dict, q in
            // this state is a final state if any of the corresponding nfa states were accepting
            dict[q] = DFAState(isFinal: q.intersection(nfa.acceptingStates).count > 0)
        }
        // Add transitions to DFAState
        for target in transitions {
            guard let state = dfa[target.key] else { continue }
            for edge in target.value {
                state.transitions[edge.key] = dfa[edge.value]
            }
        }

        self.initialState = dfa[q0]!
    }

    func validate(_ string: String) -> Bool {
        let errorState = DFAState(isFinal: false)

        return string.reduce(initialState) { (state, char) in
            state.transitions[char] ?? errorState
        }.isFinal
    }


    //    func dfaMinimization(_ initialStates: [DFAState]) {
    //        var partitions = Dictionary(grouping: initialStates, by: \.isFinal).map(\.value)
    //        var partitionCount: Int
    //
    //        repeat {
    //            partitionCount = partitions.count
    //            partitions = partitions.flatMap { partition in
    //                // TODO: check every character in alphabet, and verify that all the elements of partition end up in the *same* partition after transitioning
    //                // otherwise split into elements that lead to different partitions
    //                // p56
    //            }
    //        } while (partitions.count > partitionCount)
    //    }
}

struct MessageValidator {
    let rules: [Int: Rule]
    let dfa: DeterministicFiniteAutomaton

    init?(_ lines: [String]) {
        rules = lines.reduce(into: [:], { (result, line) in
            guard let (numberString, ruleString) = line.splitOnce(separator: ": "),
                  let number = Int(numberString),
                  let rule = Rule(ruleString) else { return }
            result[number] = rule

        })

        guard let rule0 = rules[0]?.nfaStates(rules) else { return nil }

        let alphabet = rules.reduce(into: Set<Character>()) { (set, entry) in
            if case Rule.literal(let char) = entry.value {
                set.insert(char)
            }
        }

        let nfa = NondeterministicFiniteAutomaton(initialState: rule0.start,
                                                  acceptingStates: [rule0.final],
                                                  alphabet: alphabet)
        dfa = DeterministicFiniteAutomaton(nfa)
    }

    func validate(_ string: String) -> Bool {
        return dfa.validate(string)
    }
}

let exampleInput = """
0: 4 1 5
1: 2 3 | 3 2
2: 4 4 | 5 5
3: 4 5 | 5 4
4: "a"
5: "b"

ababbb
bababa
abbbab
aaabbb
aaaabbb
"""

let input = try readResourceFile("input.txt")

verify([
    (exampleInput, 2),
    (input, 173),
]) {
    guard let (rules, messages) = $0.splitOnce(separator: "\n\n"),
          let validator = MessageValidator(rules.lines()) else { return 0 }
    return messages.lines().reduce(0) {
        $0 + (validator.validate($1) ? 1 : 0)
    }
}

/**
 --- Part Two ---

 As you look over the list of messages, you realize your matching rules aren't quite right. To fix them, completely replace rules 8: 42 and 11: 42 31 with the following:

 8: 42 | 42 8
 11: 42 31 | 42 11 31
 This small change has a big impact: now, the rules do contain loops, and the list of messages they could hypothetically match is infinite. You'll need to determine how these changes affect which messages are valid.

 Fortunately, many of the rules are unaffected by this change; it might help to start by looking at which rules always match the same set of values and how those rules (especially rules 42 and 31) are used by the new versions of rules 8 and 11.

 (Remember, you only need to handle the rules you have; building a solution that could handle any hypothetical combination of rules would be significantly more difficult.)

 For example:

 42: 9 14 | 10 1
 9: 14 27 | 1 26
 10: 23 14 | 28 1
 1: "a"
 11: 42 31
 5: 1 14 | 15 1
 19: 14 1 | 14 14
 12: 24 14 | 19 1
 16: 15 1 | 14 14
 31: 14 17 | 1 13
 6: 14 14 | 1 14
 2: 1 24 | 14 4
 0: 8 11
 13: 14 3 | 1 12
 15: 1 | 14
 17: 14 2 | 1 7
 23: 25 1 | 22 14
 28: 16 1
 4: 1 1
 20: 14 14 | 1 15
 3: 5 14 | 16 1
 27: 1 6 | 14 18
 14: "b"
 21: 14 1 | 1 14
 25: 1 1 | 1 14
 22: 14 14
 8: 42
 26: 14 22 | 1 20
 18: 15 15
 7: 14 5 | 1 21
 24: 14 1

 abbbbbabbbaaaababbaabbbbabababbbabbbbbbabaaaa
 bbabbbbaabaabba
 babbbbaabbbbbabbbbbbaabaaabaaa
 aaabbbbbbaaaabaababaabababbabaaabbababababaaa
 bbbbbbbaaaabbbbaaabbabaaa
 bbbababbbbaaaaaaaabbababaaababaabab
 ababaaaaaabaaab
 ababaaaaabbbaba
 baabbaaaabbaaaababbaababb
 abbbbabbbbaaaababbbbbbaaaababb
 aaaaabbaabaaaaababaa
 aaaabbaaaabbaaa
 aaaabbaabbaaaaaaabbbabbbaaabbaabaaa
 babaaabbbaaabaababbaabababaaab
 aabbbbbaabbbaaaaaabbbbbababaaaaabbaaabba
 Without updating rules 8 and 11, these rules only match three messages: bbabbbbaabaabba, ababaaaaaabaaab, and ababaaaaabbbaba.

 However, after updating rules 8 and 11, a total of 12 messages match:

 bbabbbbaabaabba
 babbbbaabbbbbabbbbbbaabaaabaaa
 aaabbbbbbaaaabaababaabababbabaaabbababababaaa
 bbbbbbbaaaabbbbaaabbabaaa
 bbbababbbbaaaaaaaabbababaaababaabab
 ababaaaaaabaaab
 ababaaaaabbbaba
 baabbaaaabbaaaababbaababb
 abbbbabbbbaaaababbbbbbaaaababb
 aaaaabbaabaaaaababaa
 aaaabbaabbaaaaaaabbbabbbaaabbaabaaa
 aabbbbbaabbbaaaaaabbbbbababaaaaabbaaabba
 After updating rules 8 and 11, how many messages completely match rule 0?
 */

// I think this is maybe not a big deal - just adding support for * aka "closure" aka repeated elements
// actually, wrong. This changes the language into a context-free one, since rule 11 requires matching


//: [Next](@next)
