import Foundation

func snafuToDecimal(_ character: Character) -> Int {
    switch character {
    case "=": return -2
    case "-": return -1
    case "0": return 0
    case "1": return 1
    case "2": return 2
    default: fatalError("snafu character out of range \(character)")
    }
}

public func snafuToDecimal(_ snafu: String) -> Int {
    return snafu.reversed()
        .enumerated()
        .reduce(0) { sum, nv in
            sum + (snafuToDecimal(nv.element) * pow(5, nv.offset))
        }
}

public func decimalToSnafu(_ decimal: Int) -> String {
    guard decimal > 0 else { return "0" }

    var digits = [Character]()

    var quotient = decimal, remainder: Int
    while quotient > 0 {
        (quotient, remainder) = quotient.quotientAndRemainder(dividingBy: 5)

        switch remainder {
        case 0:
            digits.append("0")
        case 1:
            digits.append("1")
        case 2:
            digits.append("2")
        case 3:
            quotient += 1
            digits.append("=")
        case 4:
            quotient += 1
            digits.append("-")
        default: fatalError("invalid remainder \(remainder)")
        }
    }

    return String(digits.reversed())
}
