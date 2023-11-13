import Foundation

enum Digit {
    case zero, one, two, three, four, five, six, seven, eight, nine, ten

    init?(_ string: String) {
        switch string.count {
        case 2:
            self = .one
        case 3:
            self = .seven
        case 4:
            self = .four
        case 7:
            self = .eight
        default:
            return nil
        }
    }
}

public struct Display {
    let output: [Digit]

    public init?(_ line: String) {
        guard let (_, outputStr) = line.splitOnce(separator: " | ") else {
            return nil
        }
        let output = outputStr.components(separatedBy: " ")
        guard output.count == 4 else {
            return nil
        }
        
        self.output = output.compactMap(Digit.init)
    }

    public func part1() -> Int {
        let desiredDigits: Set<Digit> = [.one, .four, .seven, .eight]

        return output
            .filter { desiredDigits.contains($0) }
            .count
    }
}
