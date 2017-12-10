import Foundation

public enum Direction: CustomStringConvertible {
    case up, down, left, right

    public var description: String {
        switch self {
        case .up: return "U"
        case .down: return "D"
        case .left: return "L"
        case .right: return "R"
        }
    }
}

public struct SecureVaultRoom {
    let passcode: String
    let x: Int, y: Int
    let path: [Direction]

    public static func goal(passcode: String) -> SecureVaultRoom {
        return SecureVaultRoom(passcode: passcode, x: 3, y: 3, path: [])
    }

    public init(passcode: String) {
        self.init(passcode: passcode, x: 0, y: 0, path: [])
    }

    private init(passcode: String, x: Int, y: Int, path: [Direction]) {
        self.passcode = passcode
        self.x = x
        self.y = y
        self.path = path
    }

    public func openDoors() -> [Direction] {
        let hash = (passcode + path.map { $0.description }.joined()).md5().utf8.prefix(4)

        let isUnlocked = hash.map { "bcdef".utf8.contains($0) }

        return zip([Direction.up, .down, .left, .right], isUnlocked).flatMap { (direction: Direction, isUnlocked: Bool) -> Direction? in
            isUnlocked ? direction : nil
        }
    }

    func isGoal() -> Bool {
        return x == 3 && y == 3
    }

    public func moving(_ direction: Direction) -> SecureVaultRoom? {
        var newX = x, newY = y

        switch direction {
        case .up: newY -= 1
        case .down: newY += 1
        case .left: newX -= 1
        case .right: newX += 1
        }

        if (newX < 0 || newX > 3 || newY < 0 || newY > 3) {
            return nil
        }

        return SecureVaultRoom(passcode: passcode, x: newX, y: newY, path: path + [direction])
    }

    public var pathString: String {
        return path.map { $0.description }.joined()
    }
}

extension SecureVaultRoom: Hashable {
    public static func ==(_ lhs: SecureVaultRoom, _ rhs: SecureVaultRoom) -> Bool {
        if lhs.passcode != rhs.passcode {
            // definitely not equal if they're in separate vaults
            return false
        } else if lhs.isGoal() || rhs.isGoal() {
            // Don't care how you got to the goal, they're equal
            return lhs.isGoal() == rhs.isGoal()
        } else {
            // if they have the same path, they're equal
            return lhs.path == rhs.path
        }
    }

    public var hashValue: Int {
        // must make sure goal states have same hashValue regardless of path, just use coords for hashing
        return (x.hashValue &* 31) &+ y.hashValue
    }
}

extension SecureVaultRoom: SearchState {
    public func estimatedCost(toReach goal: SecureVaultRoom) -> SearchState.Cost {
        return diff(goal.x, x) + diff(goal.y, y)
    }

    public func adjacentStates() -> AnySequence<(cost: Int, state: SecureVaultRoom)> {
        return AnySequence(self.openDoors().flatMap { self.moving($0) }.map { (cost: 1, state: $0) })
    }
}
