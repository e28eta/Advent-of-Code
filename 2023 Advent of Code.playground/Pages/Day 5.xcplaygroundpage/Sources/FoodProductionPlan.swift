import Foundation

public struct FoodProductionPlan<I: FixedWidthInteger> {
    let seeds: [I]
    let stages: [FoodProductionMap<I>]

    public func part1() -> I {
        return seeds.map { seed in
            stages.reduce(seed) { input, stage in
                stage.map(input)
            }
        }
        .min() ?? -1
    }

    public func part2() -> I {
        let seedRanges = seeds
            .sliced(into: 2)
            .compactMap {
                let start = $0[$0.startIndex]
                let count = $0[$0.startIndex + 1]
                return Range(uncheckedBounds: (start, start + count))
            }
            .reduce(into: RangeSet<I>()) { rs, r in
                rs.insert(contentsOf: r)
            }

        return stages.reduce(seedRanges) { inputRanges, stage in

            return inputRanges
                .ranges
                .reduce(into: RangeSet<I>()) { output, inputRange in
                    var cursor = inputRange.lowerBound

                    while cursor < inputRange.upperBound {
                        if let entry = stage.entries.first(where: { $0.sourceRange.contains(cursor) }) {
                            // a remapped range
                            let upper = min(inputRange.upperBound, entry.sourceRange.upperBound)

                            output.insert(contentsOf: entry.map(cursor ..< upper))
                            cursor = upper
                        } else if let entry = stage.entries.first(where: { cursor < $0.sourceRange.lowerBound }) {
                            // found next remapped range above cursor. relies on `entries` being sorted
                            let upper = min(inputRange.upperBound,
                                            entry.sourceRange.lowerBound)
                            output.insert(contentsOf: (cursor ..< upper))
                            cursor = upper
                        } else {
                            // no remapping above, just
                            // directly map everything remaining
                            let upper = inputRange.upperBound
                            output.insert(contentsOf: (cursor ..< upper))
                            cursor = upper
                        }
                    }
                }
        }
        .ranges.first?.lowerBound ?? -1
    }
}

struct FoodProductionMap<I: FixedWidthInteger> {
    struct Entry {
        let sourceRange: Range<I>
        let destinationStart: I
    }

    let name: String
    // sorted by sourceRange lower bound, ascending
    let entries: [Entry]

    func map(_ input: I) -> I {
        guard let entry = entries.first(where: { $0.sourceRange.contains(input)
        }) else { return input }

        return entry.map(input)
    }
}

public extension FoodProductionPlan {
    init(_ string: String) {
        let components = string.components(separatedBy: "\n\n")
        guard let (prefix, seeds) = components.first?.splitOnce(separator: ": "),
              prefix == "seeds"
        else {
            fatalError("bad input \(string)")
        }

        self.seeds = seeds.components(separatedBy: " ")
            .compactMap(I.init)
        self.stages = components.dropFirst(1)
            .map(FoodProductionMap.init)
    }
}

extension FoodProductionMap {
    init(_ string: some StringProtocol) {
        let lines = string.lines()

        name = lines.first ?? "unknown"
        entries = lines.dropFirst()
            .compactMap(Entry.init)
            .sorted { $0.sourceRange.lowerBound < $1.sourceRange.lowerBound }
    }
}

extension FoodProductionMap.Entry {
    init?(_ line: some StringProtocol) {
        let nums = line.components(separatedBy: " ")
            .compactMap(I.init)
        guard nums.count == 3 else {
            print("bad line? \(line)")
            return nil
        }

        self.sourceRange = Range(uncheckedBounds: (nums[1], nums[1] + nums[2]))
        self.destinationStart = nums[0]
    }

    func map(_ input: I) -> I {
        return input - sourceRange.lowerBound + destinationStart
    }

    // only valid for a range within sourceRange
    func map(_ range: Range<I>) -> Range<I> {
        precondition(sourceRange.contains(range.lowerBound) && range.upperBound <= sourceRange.upperBound)

        return Range(uncheckedBounds: (map(range.lowerBound),
                                       map(range.upperBound)))
    }
}
