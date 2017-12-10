//: [Previous](@previous)

/*: 
 # Day 15: Timing is Everything

 The halls open into an interior plaza containing a large kinetic sculpture. The sculpture is in a sealed enclosure and seems to involve a set of identical spherical capsules that are carried to the top and allowed to [bounce through the maze](https://youtu.be/IxDoO9oODOk?t=177) of spinning pieces.

 Part of the sculpture is even interactive! When a button is pressed, a capsule is dropped and tries to fall through slots in a set of rotating discs to finally go through a little hole at the bottom and come out of the sculpture. If any of the slots aren't aligned with the capsule as it passes, the capsule bounces off the disc and soars away. You feel compelled to get one of those capsules.

 The discs pause their motion each second and come in different sizes; they seem to each have a fixed number of positions at which they stop. You decide to call the position with the slot `0`, and count up for each position it reaches next.

 Furthermore, the discs are spaced out so that after you push the button, one second elapses before the first disc is reached, and one second elapses as the capsule passes from one disc to the one below it. So, if you push the button at `time=100`, then the capsule reaches the top disc at `time=101`, the second disc at `time=102`, the third disc at `time=103`, and so on.

 The button will only drop a capsule at an integer time - no fractional seconds allowed.

 For example, at `time=0`, suppose you see the following arrangement:
````
 Disc #1 has 5 positions; at time=0, it is at position 4.
 Disc #2 has 2 positions; at time=0, it is at position 1.
 ````

 If you press the button exactly at `time=0`, the capsule would start to fall; it would reach the first disc at `time=1`. Since the first disc was at position `4` at `time=0`, by `time=1` it has ticked one position forward. As a five-position disc, the next position is `0`, and the capsule falls through the slot.

 Then, at `time=2`, the capsule reaches the second disc. The second disc has ticked forward two positions at this point: it started at position `1`, then continued to position `0`, and finally ended up at position `1` again. Because there's only a slot at position `0`, the capsule bounces away.

 If, however, you wait until `time=5` to push the button, then when the capsule reaches each disc, the first disc will have ticked forward `5+1 = 6` times (to position `0`), and the second disc will have ticked forward `5+2 = 7` times (also to position `0`). In this case, the capsule would fall through the discs and come out of the machine.

 However, your situation has more than two discs; you've noted their positions in your puzzle input. What is the **first time you can press the button** to get a capsule?
 */

import Foundation

struct Disc {
    let numberOfSlots: Int
    let ordinalPosition: Int
    let initialPosition: Int

    func slotPositionForButtonPress(at time: Int) -> Int {
        return (initialPosition + ordinalPosition + time) % numberOfSlots
    }

    func isSlotAligned(at time: Int) -> Bool {
        return self.slotPositionForButtonPress(at: time) == 0
    }

    func timesWhenAligned() -> AnySequence<Int> {
        return AnySequence<Int> { () -> AnyIterator<Int> in
            let positionForButtonAtZero = (self.initialPosition + self.ordinalPosition) % self.numberOfSlots
            let firstTimeAligned = (self.numberOfSlots - positionForButtonAtZero) % self.numberOfSlots
            var currentAlignedTime = firstTimeAligned

            return AnyIterator<Int> {
                defer {
                    currentAlignedTime += self.numberOfSlots
                }
                return currentAlignedTime
            }
        }
    }
}

struct Machine {
    let discs: [Disc]

    init(_ discDefinitions: [(Int, Int)]) {
        var discs: [Disc] = []

        for (index, disc) in discDefinitions.enumerated() {
            discs.append(Disc(numberOfSlots: disc.0, ordinalPosition: index + 1, initialPosition: disc.1))
        }

        self.discs = discs
    }

    func pushButton(at time: Int) -> [Int] {
        return discs.map { $0.slotPositionForButtonPress(at: time) }
    }

    func firstTimeToPressButton() -> Int {
        let sortedDiscs = discs.sorted { $0.0.numberOfSlots > $0.1.numberOfSlots }
        guard let firstDisc = sortedDiscs.first else { return -1 }
        let rest = sortedDiscs.dropFirst()

        for time in firstDisc.timesWhenAligned() {
            if let _ = rest.first(where: { !$0.isSlotAligned(at: time) }) {
                continue
            } else {
                return time
            }
        }

        return -1
    }
}

let exampleMachine = Machine([(5, 4), (2, 1)])

for time in 0...9 {
    print(time, exampleMachine.pushButton(at: time))
}

exampleMachine.firstTimeToPressButton()


/*:
 My Input:
 ````
 Disc #1 has 5 positions; at time=0, it is at position 2.
 Disc #2 has 13 positions; at time=0, it is at position 7.
 Disc #3 has 17 positions; at time=0, it is at position 10.
 Disc #4 has 3 positions; at time=0, it is at position 2.
 Disc #5 has 19 positions; at time=0, it is at position 9.
 Disc #6 has 7 positions; at time=0, it is at position 0.
 ````
 */

let machine = Machine([(5, 2),
                       (13, 7),
                       (17, 10),
                       (3, 2),
                       (19, 9),
                       (7, 0)])

let part1Answer = machine.firstTimeToPressButton()
assert(part1Answer == 148737)

/*:
 # Part Two

 After getting the first capsule (it contained a star! what great fortune!), the machine detects your success and begins to rearrange itself.

 When it's done, the discs are back in their original configuration as if it were `time=0` again, but a new disc with `11` positions and starting at position `0` has appeared exactly one second below the previously-bottom disc.

 With this new disc, and counting again starting from `time=0` with the configuration in your puzzle input, what is the **first time you can press the button** to get another capsule?
 */

let part2Machine = Machine([(5, 2),
                            (13, 7),
                            (17, 10),
                            (3, 2),
                            (19, 9),
                            (7, 0),
                            (11, 0)])

let part2Answer = part2Machine.firstTimeToPressButton()
assert(part2Answer == 2353212)

//: [Next](@next)
