//: [Previous](@previous)

/*:
 # Day 12: Digital Plumber

 Walking along the memory banks of the stream, you find a small village that is experiencing a little confusion: some programs can't communicate with each other.

 Programs in this village communicate using a fixed system of **pipes**. Messages are passed between programs using these pipes, but most programs aren't connected to each other directly. Instead, programs pass messages between each other until the message reaches the intended recipient.

 For some reason, though, some of these messages aren't ever reaching their intended recipient, and the programs suspect that some pipes are missing. They would like you to investigate.

 You walk through the village and record the ID of each program and the IDs with which it can communicate directly (your puzzle input). Each program has one or more programs with which it can communicate, and these pipes are bidirectional; if `8` says it can communicate with `11`, then `11` will say it can communicate with `8`.

 You need to figure out how many programs are in the group that contains program ID `0`.

 For example, suppose you go door-to-door like a travelling salesman and record the following list:

 ```
 0 <-> 2
 1 <-> 1
 2 <-> 0, 3, 4
 3 <-> 2, 4
 4 <-> 2, 3, 6
 5 <-> 6
 6 <-> 4, 5
 ```

 In this example, the following programs are in the group that contains program ID `0`:

 - Program `0` by definition.
 - Program `2`, directly connected to program `0`.
 - Program `3` via program `2`.
 - Program `4` via program `2`.
 - Program `5` via programs `6`, then `4`, then `2`.
 - Program `6` via programs `4`, then `2`.

 Therefore, a total of `6` programs are in this group; all but program `1`, which has a pipe that connects it to itself.

 **How many programs** are in the group that contains program ID `0`?
 */

import Foundation

struct Program {
    let id: Int
    let connections: [Int]
}

struct ProgramGraph {
    let graph: [Int: Program]

    init(_ string: String) {
        let programs = string.lines()
            .map { line -> Program in
                let parts = line.components(separatedBy: " <-> ")
                guard parts.count == 2 else {
                    fatalError()
                }
                return Program(id: Int(parts[0])!,
                               connections: parts[1].components(separatedBy: ", ").map { Int($0)! })
            }

        graph = programs.reduce(into: [:]) {
            $0[$1.id] = $1
        }
    }

    func neighborCount(of start: Int) -> Int {
        return group(containing: start).count
    }

    func group(containing id: Int) -> Set<Int> {
        var group: Set<Int> = [id]
        var queue: [Int] = [id]

        while let nextId = queue.popLast(), let next = graph[nextId] {
            let newNeighbors = next.connections.filter { !group.contains($0) }

            queue.append(contentsOf: newNeighbors)
            group.formUnion(newNeighbors)
        }

        return group
    }

    func allGroups() -> [Set<Int>] {
        var groups: [Set<Int>] = []
        var allIds = Set(graph.keys)

        while let nextId = allIds.popFirst() {
            let nextGroup = group(containing: nextId)

            allIds.subtract(nextGroup)
            groups.append(nextGroup)
        }

        return groups
    }
}


let testData = [
    ("""
0 <-> 2
1 <-> 1
2 <-> 0, 3, 4
3 <-> 2, 4
4 <-> 2, 3, 6
5 <-> 6
6 <-> 4, 5
""", 6),
]

verify(testData, { ProgramGraph($0).neighborCount(of: 0) })

let input = try readResourceFile("input.txt")
let graph = ProgramGraph(input)
assertEqual(graph.neighborCount(of: 0), 380)

/*:
 # Part Two

 There are more programs than just the ones in the group containing program ID `0`. The rest of them have no way of reaching that group, and still might have no way of reaching each other.

 A **group** is a collection of programs that can all communicate via pipes either directly or indirectly. The programs you identified just a moment ago are all part of the same group. Now, they would like you to determine the total number of groups.

 In the example above, there were 2 groups: one consisting of programs `0,2,3,4,5,6`, and the other consisting solely of program `1`.

 **How many groups** are there in total?
 */

let testData2 = [
    ("""
0 <-> 2
1 <-> 1
2 <-> 0, 3, 4
3 <-> 2, 4
4 <-> 2, 3, 6
5 <-> 6
6 <-> 4, 5
""", 2),
]

verify(testData2) { ProgramGraph($0).allGroups().count }
assertEqual(graph.allGroups().count, 181)


//: [Next](@next)
