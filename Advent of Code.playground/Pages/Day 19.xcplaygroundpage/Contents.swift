//: [Previous](@previous)

/*:
 # Day 19: An Elephant Named Joseph

 The Elves contact you over a highly secure emergency channel. Back at the North Pole, the Elves are busy misunderstanding [White Elephant parties](https://en.wikipedia.org/wiki/White_elephant_gift_exchange).

 Each Elf brings a present. They all sit in a circle, numbered starting with position `1`. Then, starting with the first Elf, they take turns stealing all the presents from the Elf to their left. An Elf with no presents is removed from the circle and does not take turns.

 For example, with five Elves (numbered `1` to `5`):

 ````
   1
 5   2
  4 3
 ````

 * Elf `1` takes Elf `2`'s present.
 * Elf `2` has no presents and is skipped.
 * Elf `3` takes Elf `4`'s present.
 * Elf `4` has no presents and is also skipped.
 * Elf `5` takes Elf `1`'s two presents.
 * Neither Elf `1` nor Elf `2` have any presents, so both are skipped.
 * Elf `3` takes Elf `5`'s three presents.

 So, with **five** Elves, the Elf that sits starting in position `3` gets all the presents.

 With the number of Elves given in your puzzle input, **which Elf gets all the presents**?

 Your puzzle input is `3012210`.
 */

import Foundation

/*
 By inspection of first 32 cases, determined the answer to be:
 (x - 2^(floor(log2(x)))) * 2 + 1
 (x - 2^(floor(log2(x)))) is attempting to mask off the MSB of x.
 
 Looks like flp2() from http://www.hackersdelight.org/hdcodetxt/flp2.c.txt does that for me too
 */

func flp2(_ x: UInt32) -> UInt32 {
    var x = x

    for n: UInt32 in [1, 2, 4, 8, 16] {
        x |= (x >> n)
    }

    return x - (x >> 1)
}

func elfNumber(_ x: UInt32) -> UInt32 {
    let num = x - flp2(x)

    return num * 2 + 1
}

for x: UInt32 in (0...32) {
    print(x, flp2(x), elfNumber(x))
}


let input: UInt32 = 3012210
let part1Answer = elfNumber(input)
assert(part1Answer == 1830117)

/*:
 # Part Two

 Realizing the folly of their present-exchange rules, the Elves agree to instead steal presents from the Elf **directly across the circle**. If two Elves are across the circle, the one on the left (from the perspective of the stealer) is stolen from. The other rules remain unchanged: Elves with no presents are removed from the circle entirely, and the other elves move in slightly to keep the circle evenly spaced.

 For example, with five Elves (again numbered 1 to 5):

 The Elves sit in a circle; Elf `1` goes first:
 ````
   1
 5   2
  4 3
 ````

 Elves `3` and `4` are across the circle; Elf `3`'s present is stolen, being the one to the left. Elf `3` leaves the circle, and the rest of the Elves move in:
 ````
   1           1
 5   2  -->  5   2
  4 -          4
 ````

 Elf `2` steals from the Elf directly across the circle, Elf `5`:
 ````
   1         1
 -   2  -->     2
   4         4
 ````

 Next is Elf `4` who, choosing between Elves `1` and `2`, steals from Elf `1`:
 ````
 -          2
   2  -->
 4          4
 ````

 Finally, Elf `2` steals from Elf `4`:
 ````
 2
   -->  2
 -
 ````

 So, with five Elves, the Elf that sits starting in position `2` gets all the presents.

 With the number of Elves given in your puzzle input, **which Elf now gets all the presents?**
 */



//: [Next](@next)
