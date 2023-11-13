enum Digit: CaseIterable {
    case zero, one, two, three, four, five, six, seven, eight, nine

    init?(_ segments: Set<Segment>) {
        guard let digit = Digit.digitToSegments.first(where: { $0.value == segments }) else {
            print("couldn't find digit matching \(segments)")
            return nil
        }

        self = digit.key
    }

    static let digitToSegments: [Digit: Set<Segment>] = [
        .zero: Set(Segment.allCases).subtracting([.mid]),
        .one: Set([.topRight, .bottomRight]),
        .two: Set([.top, .mid, .bottom, .topRight, .bottomLeft]),
        .three: Set([.top, .mid, .bottom, .topRight, .bottomRight]),
        .four: Set([.topLeft, .mid, .topRight, .bottomRight]),
        .five: Set([.top, .mid, .bottom, .topLeft, .bottomRight]),
        .six: Set(Segment.allCases).subtracting([.topRight]),
        .seven: Set([.top, .topRight, .bottomRight]),
        .eight: Set(Segment.allCases),
        .nine: Set(Segment.allCases).subtracting([.bottomLeft]),
    ]

    var value: Int {
        switch self {
        case .zero:
            return 0
        case .one:
            return 1
        case .two:
            return 2
        case .three:
            return 3
        case .four:
            return 4
        case .five:
            return 5
        case .six:
            return 6
        case .seven:
            return 7
        case .eight:
            return 8
        case .nine:
            return 9
        }
    }
}

enum Segment: Hashable, CaseIterable {
    case top, mid, bottom
    case topLeft, bottomLeft
    case topRight, bottomRight
}

public struct Display {
    let output: [Digit]

    public init?(_ line: String) {
        guard let (patternsStr, outputStr) = line.splitOnce(separator: " | ") else {
            return nil
        }
        let output = outputStr.components(separatedBy: " ")
        guard output.count == 4 else {
            return nil
        }

        let patterns = patternsStr.components(separatedBy: " ")
            .map { Set<Character>($0) }

        var charToSegment: [Character: Segment] = [:]

        let onePattern = patterns.first(where: { $0.count == 2 })!
        let sevenPattern = patterns.first(where: { $0.count == 3 })!
        let fourPattern = patterns.first(where: { $0.count == 4 })!

        let topLeftAndMid = fourPattern.subtracting(onePattern)
        let union147 = onePattern.union(fourPattern).union(sevenPattern)

        let twoPattern = patterns.first { p in
            p.count == 5 && p.subtracting(union147).count == 2
        }!
        let threePattern = patterns.first { p in
            p.count == 5 && p.subtracting(union147).count == 1 && p.intersection(topLeftAndMid).count == 1
        }!

        let topChar = sevenPattern.subtracting(onePattern).first!
        let topRightChar = twoPattern.intersection(onePattern).first!
        let bottomRightChar = onePattern.subtracting([topRightChar]).first!
        let middleChar = threePattern.intersection(topLeftAndMid).first!
        let topLeftChar = topLeftAndMid.subtracting([middleChar]).first!
        let bottomChar = threePattern.subtracting(union147).first!
        let bottomLeftChar = twoPattern.subtracting(threePattern).first!

        charToSegment[topChar] = .top
        charToSegment[middleChar] = .mid
        charToSegment[bottomChar] = .bottom
        charToSegment[topRightChar] = .topRight
        charToSegment[bottomRightChar] = .bottomRight
        charToSegment[topLeftChar] = .topLeft
        charToSegment[bottomLeftChar] = .bottomLeft

        self.output = output.map { str in
            str.reduce(into: Set()) { s, c in
                s.insert(charToSegment[c]!)
            }
        }
        .compactMap(Digit.init)
    }

    public func part1() -> Int {
        let desiredDigits: Set<Digit> = [.one, .four, .seven, .eight]

        return output
            .filter { desiredDigits.contains($0) }
            .count
    }

    public func part2() -> Int {
        return output.reduce(0) { s, d in
            s * 10 + d.value
        }
    }
}
