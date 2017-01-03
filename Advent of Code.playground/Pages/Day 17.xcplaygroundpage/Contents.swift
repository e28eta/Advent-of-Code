//: [Previous](@previous)

/*:
 # Day 17: Two Steps Forward

 You're trying to access a secure vault protected by a `4x4` grid of small rooms connected by doors. You start in the top-left room (marked `S`), and you can access the vault (marked `V`) once you reach the bottom-right room:

 ````
 #########
 #S| | | #
 #-#-#-#-#
 # | | | #
 #-#-#-#-#
 # | | | #
 #-#-#-#-#
 # | | |
 ####### V
 ````
 Fixed walls are marked with `#`, and doors are marked with `-` or `|`.

 The doors in your **current room** are either open or closed (and locked) based on the hexadecimal [MD5](https://en.wikipedia.org/wiki/MD5) hash of a passcode (your puzzle input) followed by a sequence of uppercase characters representing the **path you have taken so far** (`U` for up, `D` for down, `L` for left, and `R` for right).

 Only the first four characters of the hash are used; they represent, respectively, the doors **up, down, left, and right** from your current position. Any `b`, `c`, `d`, `e`, or `f` means that the corresponding door is open; any other character (any number or `a`) means that the corresponding door is **closed and locked**.

 To access the vault, all you need to do is reach the bottom-right room; reaching this room opens the vault and all doors in the maze.

 For example, suppose the passcode is `hijkl`. Initially, you have taken no steps, and so your path is empty: you simply find the MD5 hash of `hijkl` alone. The first four characters of this hash are `ced9`, which indicate that up is open (`c`), down is open (`e`), left is open (`d`), and right is closed and locked (`9`). Because you start in the top-left corner, there are no "up" or "left" doors to be open, so your only choice is **down**.

 Next, having gone only one step (down, or `D`), you find the hash of `hijklD`. This produces `f2bc`, which indicates that you can go back up, left (but that's a wall), or right. Going right means hashing `hijklDR` to get `5745` - all doors closed and locked. However, going **up** instead is worthwhile: even though it returns you to the room you started in, your path would then be `DU`, opening a **different set of doors**.

 After going `DU` (and then hashing `hijklDU` to get `528e`), only the right door is open; after going `DUR`, all doors lock. (Fortunately, your actual passcode is not `hijkl`).

 Passcodes actually used by Easter Bunny Vault Security do allow access to the vault if you know the right path. For example:

 * If your passcode were `ihgpwlah`, the shortest path would be `DDRRRD`.
 * With `kglvqrro`, the shortest path would be `DDUDRLRRUDRD`.
 * With `ulqzkmiv`, the shortest would be `DRURDRUDDLLDLUURRDULRLDUUDDDRR`.
 * Given your vault's passcode, **what is the shortest path** (the actual path, not just the length) to reach the vault?
 
 Your puzzle input is `pslxynzg`.
 */

import Foundation

enum Direction: CustomStringConvertible {
    case up, down, left, right

    var description: String {
        switch self {
        case .up: return "U"
        case .down: return "D"
        case .left: return "L"
        case .right: return "R"
        }
    }
}

struct SecureVaultRoom {
    let passcode: String
    let x: Int, y: Int
    let path: [Direction]

    static func goal(passcode: String) -> SecureVaultRoom {
        return SecureVaultRoom(passcode: passcode, x: 3, y: 3, path: [])
    }

    init(passcode: String) {
        self.init(passcode: passcode, x: 0, y: 0, path: [])
    }

    private init(passcode: String, x: Int, y: Int, path: [Direction]) {
        self.passcode = passcode
        self.x = x
        self.y = y
        self.path = path
    }

    func openDoors() -> [Direction] {
        let hash = (passcode + path.map { $0.description }.joined()).md5().utf8.prefix(4)

        let isUnlocked = hash.map { "bcdef".utf8.contains($0) }

        return zip([Direction.up, .down, .left, .right], isUnlocked).flatMap { (direction: Direction, isUnlocked: Bool) -> Direction? in
            isUnlocked ? direction : nil
        }
    }

    func isGoal() -> Bool {
        return x == 3 && y == 3
    }

    func moving(_ direction: Direction) -> SecureVaultRoom? {
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
}

let examplePasscode = "hijkl"

let example = SecureVaultRoom(passcode: examplePasscode)

assert(example.openDoors() == [.up, .down, .left])
assert(example.moving(.down)!.openDoors() == [.up, .left, .right])
assert(example.moving(.down)!.moving(.right)!.openDoors() == [])
assert(example.moving(.down)!.moving(.up)!.openDoors() == [.right])
assert(example.moving(.down)!.moving(.up)!.moving(.right)!.openDoors() == [])


extension SecureVaultRoom: Hashable {
    static func ==(_ lhs: SecureVaultRoom, _ rhs: SecureVaultRoom) -> Bool {
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

    var hashValue: Int {
        // must make sure goal states have same hashValue regardless of path, just use coords for hashing
        return (x.hashValue &* 31) &+ y.hashValue
    }
}

extension SecureVaultRoom: SearchState {
    func estimatedCost(toReach goal: SecureVaultRoom) -> SearchState.Cost {
        return diff(goal.x, x) + diff(goal.y, y)
    }

    func adjacentStates() -> AnySequence<(cost: Int, state: SecureVaultRoom)> {
        return AnySequence(self.openDoors().flatMap { self.moving($0) }.map { (cost: 1, state: $0) })
    }
}

func part1(passcode: String) -> String? {
    let initialState = SecureVaultRoom(passcode: passcode)
    let goal = SecureVaultRoom.goal(passcode: passcode)
    let aStar = AStarSearch(initial: initialState, goal: goal)
    guard let shortestPath = aStar.shortestPath() else {
        return nil
    }


    return shortestPath.steps.last!.path.map { $0.description }.joined()
}

assert(part1(passcode: examplePasscode) == nil)

for (passcode, expectedPath) in [("ihgpwlah", "DDRRRD"), ("kglvqrro", "DDUDRLRRUDRD"), ("ulqzkmiv", "DRURDRUDDLLDLUURRDULRLDUUDDDRR")] {
    assert(part1(passcode: passcode) == expectedPath)
}


let part1Answer = part1(passcode: "pslxynzg")
assert(part1Answer == "DDRRUDLRRD")

//: [Next](@next)
