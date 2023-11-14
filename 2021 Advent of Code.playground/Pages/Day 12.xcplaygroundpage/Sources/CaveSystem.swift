import Foundation

enum CaveType {
    case small, large
}

struct Cave {
    let type: CaveType
    let label: String
    let neighbors: [String]

    init(_ label: String, neighbors: [String]) {
        self.type = label.allSatisfy(\.isLowercase) ? .small : .large
        self.label = label
        self.neighbors = neighbors
    }
}

public struct CaveSystem {
    let caves: [String: Cave]

    let startCave = "start"
    let endCave = "end"

    public init(_ string: String) {
        var paths: [String: [String]] = [:]

        for line in string.lines() {
            if let (left, right) = line.splitOnce(separator: "-") {
                paths[String(left), default: []].append(String(right))
                paths[String(right), default: []].append(String(left))
            }
        }

        caves = paths.reduce(into: [:]) { d, kv in
            d[kv.key] = Cave(kv.key, neighbors: kv.value)

        }
    }

    struct SearchState {
        let visitedSmallCaves: Set<String>
        let currentCave: String
        let secondVisitAllowed: Bool
    }

    public func allPathCount(allowSecondVisit: Bool = false) -> Int {
        guard let _ = caves[self.startCave],
              let _ = caves[self.endCave] else {
            fatalError("missing start or end cave")
        }

        var pathCount = 0
        var caveQueue = [SearchState(visitedSmallCaves: [startCave],
                                     currentCave: startCave,
                                     secondVisitAllowed: allowSecondVisit)]

        while !caveQueue.isEmpty {
            let state = caveQueue.removeFirst()

            for neighbor in caves[state.currentCave]!.neighbors {
                if neighbor == startCave {
                    // never allowed to return to start
                    continue
                }
                
                if state.visitedSmallCaves.contains(neighbor) && !state.secondVisitAllowed {
                    // already been there too many times
                    continue
                }

                if neighbor == endCave {
                    // found a path to endCave, keep looking for more
                    pathCount += 1
                    continue
                }

                caveQueue.append(state.visiting(caves[neighbor]!))
            }
        }

        return pathCount
    }
}


extension CaveSystem.SearchState {
    func visiting(_ cave: Cave) -> CaveSystem.SearchState {
        var secondVisitAllowed = self.secondVisitAllowed
        var smallCaves = self.visitedSmallCaves

        if case .small = cave.type {
            if smallCaves.contains(cave.label) {
                precondition(secondVisitAllowed, "disallowed 2nd visit")
                // consumes the allowed second visit
                secondVisitAllowed = false
            } else {
                smallCaves.insert(cave.label)
            }
        }

        return CaveSystem.SearchState(visitedSmallCaves: smallCaves,
                                      currentCave: cave.label,
                                      secondVisitAllowed: secondVisitAllowed)
    }
}
