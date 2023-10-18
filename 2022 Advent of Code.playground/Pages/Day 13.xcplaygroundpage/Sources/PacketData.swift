import Foundation

public enum PacketData {
    indirect case list([PacketData])
    case int(Int)

    init?(from jsonObject: Any) {
        if let num = jsonObject as? Int {
            self = .int(num)
        } else if let arr = jsonObject as? Array<Any> {
            let contents = arr.compactMap(PacketData.init)
            self = .list(contents)
        } else {
            print("unknown object inside PacketData \(jsonObject)")
            return nil
        }
    }

    enum ComparisonResult: Error {
        case correctOrder, incorrectOrder
    }

    public static func <(_ lhs: PacketData, _ rhs: PacketData) -> Bool {
        do {
            try compare(lhs, rhs)
        } catch PacketData.ComparisonResult.correctOrder {
            return true
        } catch PacketData.ComparisonResult.incorrectOrder {
            return false
        } catch {
            fatalError("unexpected error thrown \(error)")
        }

        fatalError("left and right were the same?")
    }

    // I _think_ throwing a result when found leads to "cleaner" code in this
    // function. I suspect part2 will make this messy though
    public static func compare(_ lhs: PacketData, _ rhs: PacketData) throws {
        switch (lhs, rhs) {
        case let (.int(left), .int(right)):
            if left < right {
                throw ComparisonResult.correctOrder
            } else if left > right {
                throw ComparisonResult.incorrectOrder
            }
            // else continue checking
        case let (.list(left), .list(right)):
            try zip(left, right).forEach(compare)

            // didn't resolve, check which list was longer
            if left.count < right.count {
                throw ComparisonResult.correctOrder
            } else if left.count > right.count {
                throw ComparisonResult.incorrectOrder
            }
            // else continue checking
        case (.int, .list):
            try compare(.list([lhs]), rhs)
        case (.list, .int):
            try compare(lhs, .list([rhs]))
        }
    }
}

public func parseInput(_ string: String) -> [(PacketData, PacketData)] {
    return string.components(separatedBy: "\n\n")
        .map { pairOfLines in
            let pairOfLists = pairOfLines.trimmingCharacters(in: .whitespacesAndNewlines)
                .lines()
                .compactMap { line in
                    line.data(using: .utf8)
                }
                .compactMap { data in
                    try? JSONSerialization.jsonObject(with: data)
                }
                .compactMap(PacketData.init)

            return (pairOfLists[0], pairOfLists[1])
        }
}
