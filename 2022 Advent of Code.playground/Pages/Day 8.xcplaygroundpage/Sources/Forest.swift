import Foundation

public class Forest {
    public let MIN_HEIGHT = 0
    public let MAX_HEIGHT = 9


    public struct Tree {
        public let height: Int
        public var visible: Bool = false
        public var sceneryScore: Int = 1
    }

    public var trees: [[Tree]]

    public init?(_ input: String) {
        trees = input.lines()
            .map { line in
                line.compactMap { treeChar in
                    Int(String(treeChar)).map { height in
                        Tree(height: height)
                    }
                }
            }

        guard let forestWidth = trees.first?.count,
              trees.firstIndex(where: { $0.count != forestWidth }) == nil else {
            // empty forest, or different sized rows
            return nil
        }
    }

    public func updateVisibility() {
        for indices in everyIterationOrder() {
            var previousMax = MIN_HEIGHT - 1

            for (row, col) in indices where trees[row][col].height > previousMax {
                trees[row][col].visible = true
                previousMax = trees[row][col].height
                if previousMax == MAX_HEIGHT { break }
            }
        }
    }

    public func visibleTrees() -> Int {
        return trees.reduce(0) { (sum, row) in
            sum + row.filter(\.visible).count
        }
    }

    public func updateScenicScores() {
        for indices in everyIterationOrder() {
            // one for each height, initially there are zero trees visible in this direction
            // because we're at the edge of the forest
            var treesInView = Array(repeating: 0, count: 10)

            for (row, col) in indices {
                let height = trees[row][col].height
                // might be *0, by problem definition
                trees[row][col].sceneryScore *= treesInView[height]

                // all trees at this height or lower can *only* see the current tree
                for idx in (0...height) {
                    treesInView[idx] = 1
                }
                // any trees taller, can see one more tree than they used to
                if (height < 9) {
                    for idx in ((height+1)..<10) {
                        treesInView[idx] += 1
                    }
                }
            }
        }
    }

    public func mostScenicScore() -> Int? {
        return trees.flatMap { row in
            row.map(\.sceneryScore)
        }.max()
    }

    public func treeHeights() -> String {
        trees.map { row in
            row.map { tree in tree.height.description }.joined(separator: "")
        }.joined(separator: "\n")
    }

    public func treeVisibilities() -> String {
        trees.map { row in
            row.map { tree in tree.visible ? "t" : "f" }.joined(separator: "")
        }.joined(separator: "\n")
    }

    public func treeScores() -> String {
        trees.map { row in
            row.map { tree in "\(tree.sceneryScore)\t"}.joined(separator: "")
        }.joined(separator: "\n")
    }

    /**
     Nested sequences. Inner sequence is the (row,col) index of a tree one row at a time, or one column at a time.
     Outer sequence goes through each row and each column, in forward and reverse order.

     Specifically, for a group of 4 trees in a square:
     ```
     AB
     CD
     ```

     The outer sequence will have 8 elements, and the inner sequences will only have two, the indices of these trees:
     - A, B
     - C, D
     - B, A
     - D, C
     - A, C
     - B, D
     - C, A
     - D, B
     */
    public func everyIterationOrder() -> AnySequence<AnySequence<(Int, Int)>> {
        let rowRange = (trees.startIndex ..< trees.endIndex)
        let colRange = (trees[trees.startIndex].startIndex ..< trees[trees.startIndex].endIndex)

        let rowOrder = rowRange.lazy.map { row in
            AnySequence(colRange.lazy.map { col in (row, col) })
        }
        let rowOrderColumnsReversed = rowRange.lazy.map { row in
            AnySequence(colRange.lazy.reversed().map { col in (row, col) })
        }
        let columnOrder = colRange.lazy.map { col in
            AnySequence(rowRange.lazy.map { row in (row, col) })
        }
        let columnOrderReversed = colRange.lazy.map { col in
            AnySequence(rowRange.lazy.reversed().map { row in (row, col) })
        }

        return AnySequence(chain(chain(chain(rowOrder, rowOrderColumnsReversed), columnOrder), columnOrderReversed))
    }
}
