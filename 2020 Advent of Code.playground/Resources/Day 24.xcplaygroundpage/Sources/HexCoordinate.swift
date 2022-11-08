import Foundation

public struct HexCoordinate: Hashable, CustomStringConvertible {
    public let x: Int, y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public init<S: Sequence<Character>>(_ string: S) throws {
        var x = 0, y = 0
        var chars = string.makeIterator()
        var next = chars.next()

        while next != nil {
            switch next {
            case "w":
                x -= 2
            case "e":
                x += 2
            case "n":
                y += 1
                next = chars.next()
                switch next {
                case "w":
                    x -= 1
                case "e":
                    x += 1
                default:
                    fatalError()
                }
            case "s":
                y -= 1
                next = chars.next()
                switch next {
                case "w":
                    x -= 1
                case "e":
                    x += 1
                default:
                    fatalError()
                }
            default:
                fatalError()
            }

            next = chars.next()
        }

        self.x = x
        self.y = y
    }

    public func neighbors() -> [HexCoordinate] {
        return [
            (-2, 0),
            (-1, 1),
            (-1, -1),
            (1, 1),
            (1, -1),
            (2, 0)
        ].map { (dx, dy) in
            HexCoordinate(x: x + dx, y: y + dy)
        }
    }

    public var description: String {
        return "(\(x),\(y))"
    }
}
